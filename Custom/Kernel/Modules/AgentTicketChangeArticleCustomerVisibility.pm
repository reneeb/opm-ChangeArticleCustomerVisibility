# --
# Copyright (C) 2019 Perl-Services.de, http://perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AgentTicketChangeArticleCustomerVisibility;
 
use strict;
use warnings;
 
our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;
 
    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}
 
sub Run {
    my ( $Self, %Param ) = @_;

    my $LayoutObject  = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject   = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $TicketObject  = $Kernel::OM->Get('Kernel::System::Ticket');
    my $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');
    my $DBObject      = $Kernel::OM->Get('Kernel::System::DB');

    my @Params = qw(IsVisibleForCustomer ArticleID TicketID);
    my %GetParam;

    for my $Param ( @Params ) {
        $GetParam{$Param} = $ParamObject->GetParam( Param => $Param ) // '';
    }

    $GetParam{IsVisibleForCustomer} ||= 0;
    $GetParam{IsVisibleForCustomer}   = 1 if $GetParam{IsVisibleForCustomer};

    if ( $Self->{Subaction} eq 'ChangeVisibility' && $GetParam{ArticleID} ) {
        my $SQL     = 'UPDATE article SET is_visible_for_customer = ? WHERE id = ?';
        my $Success = $DBObject->Do(
            SQL  => $SQL,
            Bind => [ \$GetParam{IsVisibleForCustomer}, \$GetParam{ArticleID} ],
        );

        if ( $Success ) {
            $TicketObject->_TicketCacheClear( TicketID => $GetParam{TicketID} );

            return $LayoutObject->PopupClose(
                URL => 'Action=AgentTicketZoom&TicketID=' . $GetParam{TicketID},
            );
        }
    }

    my $Backend = $ArticleObject->BackendForArticle(
        TicketID  => $GetParam{TicketID},
        ArticleID => $GetParam{ArticleID},
    );

    my %Article = $Backend->ArticleGet(
        TicketID  => $GetParam{TicketID},
        ArticleID => $GetParam{ArticleID},
    );

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

