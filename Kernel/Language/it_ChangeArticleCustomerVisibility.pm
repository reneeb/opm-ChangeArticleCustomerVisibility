# --
# Copyright (C) 2023 Università di Genova
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Language::it_ChangeArticleCustomerVisibility;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    my $Lang = $Self->{Translation};

    return if ref $Lang ne 'HASH';

    # Custom/Kernel/Output/HTML/FilterElementPost/ChangeArticleType.pm
    $Lang->{'Change Article Visibility'} = 'Cambia visibilità articolo';
    $Lang->{'Change article visibility.'} = 'Cambia visibilità articolo.';

    $Lang->{'Switched on customer visibility'} = 'Rendi visibile al cliente';
    $Lang->{'Switched off customer visibility'} = 'Rendi non visibile al cliente';

    return 1;
}

1;
