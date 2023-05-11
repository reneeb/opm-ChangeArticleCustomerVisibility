# --
# Copyright (C) 2022 - 2023 Perl-Services.de, https://www.perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package var::packagesetup::ChangeArticleCustomerVisibility;

use strict;
use warnings;

use utf8;

use List::Util qw(first);

our @ObjectDependencies = qw(
    Kernel::Config
    Kernel::System::SysConfig
    Kernel::System::DB
    Kernel::System::Stats
);

=head1 SYNOPSIS

All functions

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

=item CodeInstall()

run the code install part

    my $Result = $CodeObject->CodeInstall();

=cut

sub CodeInstall {
    my ( $Self, %Param ) = @_;

    # create dynamic fields 
    $Self->_DoSysConfigChanges();

    return 1;
}

=item CodeReinstall()

run the code reinstall part

    my $Result = $CodeObject->CodeReinstall();

=cut

sub CodeReinstall {
    my ( $Self, %Param ) = @_;

    $Self->_DoSysConfigChanges();

    return 1;
}

=item CodeUpgrade()

run the code upgrade part

    my $Result = $CodeObject->CodeUpgrade();

=cut

sub CodeUpgrade {
    my ( $Self, %Param ) = @_;

    $Self->_DoSysConfigChanges();

    return 1;
}

=item CodeUninstall()

run the code uninstall part

    my $Result = $CodeObject->CodeUninstall();

=cut

sub CodeUninstall {
    my ( $Self, %Param ) = @_;

    $Self->_DoSysConfigChanges();

    return 1;
}

=item _DoSysConfigChanges()

=cut

sub _DoSysConfigChanges {
    my ($Self, %Param) = @_;

    my $SysConfigObject = $Kernel::OM->Get('Kernel::System::SysConfig');
    my $ConfigObject    = $Kernel::OM->Get('Kernel::Config');

    my $Base           = 'Ticket::Frontend::Article::Actions';
    my $ArticleActions = $ConfigObject->Get($Base) || {};

    my @Settings;
    my $Changed;

    for my $Channel ( qw/Internal Phone Email/ ) {
        if ( !$ArticleActions->{$Channel}->{ChangeArticleCustomerVisibility} ) {
            $ArticleActions->{$Channel}->{ChangeArticleCustomerVisibility} = {
                Module => 'Kernel::Output::HTML::ArticleAction::AgentTicketChangeArticleCustomerVisibility',
                Prio   => 401,
                Valid  => 1,
            };

            push @Settings, {
                Name           => $Base . '###' . $Channel,
                EffectiveValue => $ArticleActions->{$Channel},
            };

            $Changed = 1;
        }
    }

    if ( $Changed ) {
        # update the sysconfig
        my $Success = $SysConfigObject->SettingsSet(
            UserID   => 1,
            Comments => 'Update ArticleActions',
            Settings => \@Settings,
        );
    }
}

1;

=back

=head1 TERMS AND CONDITIONS

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/gpl-2.0.txt>.

=cut

