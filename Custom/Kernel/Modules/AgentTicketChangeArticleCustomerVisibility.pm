# --
# Copyright (C) 2019 - 2023 Perl-Services.de, https://perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AgentTicketChangeArticleCustomerVisibility;
 
use strict;
use warnings;
 
our $ObjectManagerDisabled = 1;

use Kernel::System::VariableCheck qw(:all);
use Kernel::Language qw(Translatable);

sub new {
    my ( $Type, %Param ) = @_;
 
    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}
 
sub Run {
    my ( $Self, %Param ) = @_;

    my $ConfigObject  = $Kernel::OM->Get('Kernel::Config');
    my $LayoutObject  = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject   = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $TicketObject  = $Kernel::OM->Get('Kernel::System::Ticket');
    my $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');
    my $DBObject      = $Kernel::OM->Get('Kernel::System::DB');

    my $DynamicFieldObject        = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

    my @Params = qw(IsVisibleForCustomer ArticleID TicketID);
    my %GetParam;

    for my $Param ( @Params ) {
        $GetParam{$Param} = $ParamObject->GetParam( Param => $Param ) // '';
    }

    $GetParam{IsVisibleForCustomer} ||= 0;
    $GetParam{IsVisibleForCustomer}   = 1 if $GetParam{IsVisibleForCustomer};

    # get ACL restrictions
    my %PossibleActions = ( 1 => $Self->{Action} );

    my $ACL = $TicketObject->TicketAcl(
        Data          => \%PossibleActions,
        Action        => $Self->{Action},
        TicketID      => $Self->{TicketID},
        ReturnType    => 'Action',
        ReturnSubType => '-',
        UserID        => $Self->{UserID},
    );

    my %AclAction = $TicketObject->TicketAclActionData();

    # check if ACL restrictions exist
    if ( $ACL || IsHashRefWithData( \%AclAction ) ) {

        my %AclActionLookup = reverse %AclAction;

        # show error screen if ACL prohibits this action
        if ( !$AclActionLookup{ $Self->{Action} } ) {
            return $LayoutObject->NoPermission( WithHeader => 'yes' );
        }
    }

    my $Config = $ConfigObject->Get('Ticket::Frontend::' . $Self->{Action});

    # get the dynamic fields for this screen
    my $DynamicField = $DynamicFieldObject->DynamicFieldListGet(
        Valid       => 1,
        ObjectType  => [ 'Article' ],
        FieldFilter => $Config->{DynamicField} || {},
    );

    my %DynamicFieldData;
    my %DynamicFieldError;

    DYNAMICFIELD:
    for my $DynamicFieldConfig ( @{$DynamicField} ) {

        next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

        my $Name = $DynamicFieldConfig->{Name};

        # extract the dynamic field value from the web request
        $DynamicFieldData{Value}->{ $Name } =
            $DynamicFieldBackendObject->EditFieldValueGet(
            DynamicFieldConfig => $DynamicFieldConfig,
            ParamObject        => $ParamObject,
            LayoutObject       => $LayoutObject,
        );
 

        my $IsACLReducible = $DynamicFieldBackendObject->HasBehavior(
            DynamicFieldConfig => $DynamicFieldConfig,
            Behavior           => 'IsACLReducible',
        );

        $DynamicFieldData{ACLReducible}->{$Name} = $IsACLReducible;

        my $PossibleValues = $DynamicFieldBackendObject->PossibleValuesGet(
            DynamicFieldConfig => $DynamicFieldConfig,
        );

        $DynamicFieldData{PossibleValues}->{$Name} = $PossibleValues;
        if ( $IsACLReducible ) {

            # convert possible values key => value to key => key for ACLs using a Hash slice
            my %AclData = %{$PossibleValues};
            @AclData{ keys %AclData } = keys %AclData;

            # set possible values filter from ACLs
            my $ACL = $TicketObject->TicketAcl(
                %GetParam,
                Action        => $Self->{Action},
                TicketID      => $Self->{TicketID},
                QueueID       => $Self->{QueueID},
                ReturnType    => 'Ticket',
                ReturnSubType => 'DynamicField_' . $Name,
                Data          => \%AclData,
                UserID        => $Self->{UserID},
            );

            if ($ACL) {
                my %Filter = $TicketObject->TicketAclData();

                # convert Filer key => key back to key => value using map
                %{$PossibleValues} = map { $_ => $PossibleValues->{$_} } keys %Filter;
            }

            my $DataValues = $DynamicFieldBackendObject->BuildSelectionDataGet(
                DynamicFieldConfig => $DynamicFieldConfig,
                PossibleValues     => $PossibleValues,
                Value              => $DynamicFieldData{Value}->{$Name},
            ) || $PossibleValues;

            $DynamicFieldData{PossibleValues}->{$Name} = $DataValues;
        }

        if ( $Self->{Subaction} && $Self->{Subaction} ne 'AJAXUpdate' ) {
            my $ValidationResult = $DynamicFieldBackendObject->EditFieldValueValidate(
                DynamicFieldConfig   => $DynamicFieldConfig,
                PossibleValuesFilter => $DynamicFieldData{PossibleValues}->{$Name},
                ParamObject          => $ParamObject,
                Mandatory            => $Config->{DynamicField}->{$Name} == 2,
            );

            if ( IsHashRefWithData( $ValidationResult ) && $ValidationResult->{ServerError} ) {
                $DynamicFieldError{$Name} = $ValidationResult;
            }
        }
    }

    # convert dynamic field values into a structure for ACLs
    my %DynamicFieldACLParameters;
    DYNAMICFIELDITEM:
    for my $Name ( sort keys %{ $DynamicFieldData{Value} || {} } ) {
        next DYNAMICFIELDITEM if !$Name;
        next DYNAMICFIELDITEM if !defined $DynamicFieldData{Value}->{$Name};

        $DynamicFieldACLParameters{ 'DynamicField_' . $Name } = $DynamicFieldData{Value}->{$Name};
    }

    $GetParam{DynamicField} = \%DynamicFieldACLParameters;

    my $Backend = $ArticleObject->BackendForArticle(
        TicketID  => $GetParam{TicketID},
        ArticleID => $GetParam{ArticleID},
    );

    my %Article = $Backend->ArticleGet(
        TicketID      => $GetParam{TicketID},
        ArticleID     => $GetParam{ArticleID},
        DynamicFields => 1,
    );

    my $Key = 'IsVisibleForCustomer';
    if ( $Self->{Subaction} eq 'Toggle' ) {
        $Self->{Subaction} = 'ChangeVisibility';

        $GetParam{$Key} = $Article{$Key} ? 0 : 1;
    }

    if ( $Self->{Subaction} eq 'ChangeVisibility' && $GetParam{ArticleID} && !%DynamicFieldError ) {
        my $VisibilityChanged = ( $GetParam{$Key} == $Article{$Key} ) ? 0 : 1;
        my $Success           = $VisibilityChanged ? 0 : 1;

        if ( $VisibilityChanged ) {
            my $SQL     = 'UPDATE article SET is_visible_for_customer = ? WHERE id = ?';
            $Success = $DBObject->Do(
                SQL  => $SQL,
                Bind => [ \$GetParam{$Key}, \$GetParam{ArticleID} ],
            );

            if ( $Success ) {
                my $OnOff = $GetParam{$Key} ? 'on' : 'off';

                $TicketObject->HistoryAdd(
                    Name         => ( sprintf "Switched %s customer visibility", $OnOff ),
                    HistoryType  => 'Misc',
                    TicketID     => $GetParam{TicketID},
                    ArticleID    => $GetParam{ArticleID},
                    CreateUserID => $Self->{UserID},
                );
            }
        }

        DYNAMICFIELD:
        for my $DynamicFieldConfig ( @{$DynamicField} ) {
            next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

            my $Name = $DynamicFieldConfig->{Name};

            # set the value
            my $Success = $DynamicFieldBackendObject->ValueSet(
                DynamicFieldConfig => $DynamicFieldConfig,
                ObjectID           => $GetParam{ArticleID},
                Value              => $DynamicFieldData{Value}->{$Name},
                UserID             => $Self->{UserID},
            );
        }

        if ( $Success ) {
            $TicketObject->_TicketCacheClear( TicketID => $GetParam{TicketID} );

            return $LayoutObject->PopupClose(
                URL => 'Action=AgentTicketZoom&TicketID=' . $GetParam{TicketID},
            );
        }
    }
    elsif ( $Self->{Subaction} eq 'AJAXUpdate' ) {
        # update Dynamic Fields Possible Values via AJAX
        my @DynamicFieldAJAX;

        # cycle through the activated Dynamic Fields for this screen
        DYNAMICFIELD:
        for my $DynamicFieldConfig ( @{$DynamicField} ) {
            next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

            my $Name = $DynamicFieldConfig->{Name};

            next DYNAMICFIELD if !$DynamicFieldData{ACLReducible}->{$Name};

            push(
                @DynamicFieldAJAX,
                {
                    Name        => 'DynamicField_' . $Name,
                    Data        => $DynamicFieldData{PossibleValues}->{$Name},
                    SelectedID  => $DynamicFieldData{Value}->{$Name},
                    Translation => $DynamicFieldConfig->{Config}->{TranslatableValues} || 0,
                    Max         => 100,
                }
            );
        }

        my $JSON = $LayoutObject->BuildSelectionJSON(
            \@DynamicFieldAJAX,
        );

        return $LayoutObject->Attachment(
            ContentType => 'application/json; charset=' . $LayoutObject->{Charset},
            Content     => $JSON,
            Type        => 'inline',
            NoCache     => 1,
        );
    }

    # Dynamic fields
    DYNAMICFIELD:
    for my $DynamicFieldConfig ( @{$DynamicField} ) {
        next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

        my $Name = $DynamicFieldConfig->{Name};

        my $Class = '';
        if ( $Config->{DynamicField}->{$Name} == 2 ) {
            $Class = 'Validate_Required';
        }

        my $Value = $Article{'DynamicField_' . $Name};

        # Get field html.
        my $DynamicFieldHTML = $DynamicFieldBackendObject->EditFieldRender(
            DynamicFieldConfig   => $DynamicFieldConfig,
            PossibleValuesFilter => $DynamicFieldData{PossibleValues}->{$Name},
            ServerError          => $DynamicFieldError{$Name}->{ServerError} || '',
            ErrorMessage         => $DynamicFieldError{$Name}->{ErrorMessage} || '',
            Mandatory            => ( $Class eq 'Validate_Required' ) ? 1 : 0,
            Class                => $Class,
            LayoutObject         => $LayoutObject,
            ParamObject          => $ParamObject,
            AJAXUpdate           => 1,
            Value                => $Value,
            UpdatableFields      => [
                grep {
                    $DynamicFieldData{ACLReducible}->{$_}
                } keys %{ $DynamicFieldData{ACLReducible} || {} }
            ],
        );

        $LayoutObject->Block(
            Name => 'DynamicField',
            Data => {
                Name  => $DynamicFieldConfig->{Name},
                Label => $DynamicFieldHTML->{Label},
                Field => $DynamicFieldHTML->{Field},
            },
        );
    }

    my $Output = $LayoutObject->Header( Type => 'Small' );
    $Output .= $LayoutObject->Output(
        TemplateFile => 'AgentTicketChangeArticleCustomerVisibility',
        Data         => {
            %Param,
            %GetParam,
            %Article,
        },
    );
    $Output .= $LayoutObject->Footer( Type => 'Small' );

    return $Output;
}
 
1;

