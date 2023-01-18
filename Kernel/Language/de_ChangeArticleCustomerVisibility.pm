# --
# Copyright (C) 2019 - 2023 Perl-Services, https://www.perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Language::de_ChangeArticleCustomerVisibility;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    my $Lang = $Self->{Translation};

    return if ref $Lang ne 'HASH';

    # Custom/Kernel/Output/HTML/FilterElementPost/ChangeArticleType.pm
    $Lang->{'Change Article Visibility'} = 'Artikelsichtbarkeit ändern';
    $Lang->{'Change article visibility.'} = 'Artikelsichtbarkeit ändern.';

    $Lang->{'Switched on customer visibility'} = 'Artikelsichtbarkeit für Kunden angeschaltet';
    $Lang->{'Switched off customer visibility'} = 'Artikelsichtbarkeit für Kunden ausgeschaltet';

    return 1;
}

1;
