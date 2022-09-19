# --
# Copyright (C) 2019 Perl-Services.de, http://perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::FilterElementPost::ChangeArticleCustomerVisibility;

use strict;
use warnings;

our @ObjectDependencies = (
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LanguageObject = $Kernel::OM->Get('Kernel::Language');
    my $LayoutObject   = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject    = $Kernel::OM->Get('Kernel::System::Web::Request');

    my $Title    = $LanguageObject->Translate('Change Article Visibility');
    my $Baselink = $LayoutObject->{Baselink};
    my $TicketID = $ParamObject->GetParam( Param => 'TicketID' );

    my @ArticleIDs = ${ $Param{Data} } =~ m{<a \s name="Article(\d+)"}xms;

    ${ $Param{Data} } =~ s{ ( <a \s name="Article(\d+)" .*? <ul \s class="Actions"> ) \s* <li[^>]*?>}{$1 . $Self->__Linkify( $Baselink, $TicketID, $2, $Title ) . '<li>';}exmsg;

    return 1;
}

sub __Linkify {
    my ($Self, $Baselink, $TicketID, $ArticleID, $Title ) = @_;

    my $Link = qq~
        <li class="ChangeArticleCustomerVisibilityLink">
            <a href="${Baselink}Action=AgentTicketChangeArticleCustomerVisibility;TicketID=$TicketID;ArticleID=$ArticleID" title="$Title" class="AsPopup Popup_Type_TicketAction">$Title</a>
        </li>
    ~;

    return $Link;
}

1;
