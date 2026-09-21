-- Team logos, matched by name (same defensive approach as everything else
-- BBGM-adjacent in this app) rather than assuming row order or ids.
alter table public.teams add column logo_url text;

update public.teams set logo_url = 'assets/logos/blankendorf-monstrosities.png' where name = 'Blankendorf Monstrosities';
update public.teams set logo_url = 'assets/logos/flamington-tuxedos.png' where name = 'Flamington Tuxedos';
update public.teams set logo_url = 'assets/logos/jackson-heights-lew-crew.png' where name = 'Jackson Heights Lew Crew';
update public.teams set logo_url = 'assets/logos/la-magic-wiltworthy-kobronabitches.png' where name = 'Los Angeles Magic Wiltworthy Kobronabitches';
update public.teams set logo_url = 'assets/logos/laurel-canyon-naughty-chauffeurs.png' where name = 'Laurel Canyon Naughty Chauffeurs';
update public.teams set logo_url = 'assets/logos/oakland-paint-patrol.png' where name = 'Oakland Paint Patrol';
update public.teams set logo_url = 'assets/logos/queens-lew-crew-2-electric-boogaloo.png' where name = 'Queens Lew Crew 2, Electric Boogaloo';
update public.teams set logo_url = 'assets/logos/san-francisco-3-deep.png' where name = 'San Francisco 3 Deep';
