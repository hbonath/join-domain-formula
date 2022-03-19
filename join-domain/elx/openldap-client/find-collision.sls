#
# Salt state for downloading, installing and configuring OS-native
# OpenLDAP clients, then configuring to pull necessary information
# from an LDAP directory-source (e.g., Active Directory)
#
#################################################################
{%- from tpldir ~ '/map.jinja' import join_domain with context %}

{#- Set location for helper-files #}
{%- set files = tpldir ~ '/files' %}

RPM-installs:
  pkg.installed:
    - pkgs:
{%- if salt['grains.get']('osfamilly') == 'RedHat' %}
      - openldap-clients
      - bind-utils
{%- elif salt['grains.get']('os_family') == 'Debian' %}
      - ldap-utils
      - dnsutils
{%- endif %}
    - allow_updates: True

LDAP-FindCollison:
  cmd.script:
    - cwd: '/root'
{%- if join_domain.ad_site_name and join_domain.get("encrypted_password") %}
    - name: 'find-collisions.sh -d "{{ join_domain.dns_name }}" -s "{{ join_domain.ad_site_name }}" -u "{{ join_domain.username }}" -c "{{ join_domain.encrypted_password }}" -k "{{ join_domain.key }}" --mode saltstack'
{%- elif join_domain.ad_site_name and join_domain.get("password") %}
    - name: 'find-collisions.sh -d "{{ join_domain.dns_name }}" -s "{{ join_domain.ad_site_name }}" -u "{{ join_domain.username }}" -p "{{ join_domain.password }}" --mode saltstack'
{%- elif join_domain.get("encrypted_password") %}
    - name: 'find-collisions.sh -d "{{ join_domain.dns_name }}" -u "{{ join_domain.username }}" -c "{{ join_domain.encrypted_password }}" -k "{{ join_domain.key }}" --mode saltstack'
{%- else %}
    - name: 'find-collisions.sh -d "{{ join_domain.dns_name }}" -u "{{ join_domain.username }}" -p "{{ join_domain.password }}" --mode saltstack'
{%- endif %}
{%- if salt['pillar.get']('join-domain:lookup:ad_connector', None) == 'pbis' %}
    - unless: /opt/pbis/bin/domainjoin-cli query | grep -qi "Distinguished Name"
{%- endif %}
    - require:
      - pkg: RPM-installs
    - source: 'salt://{{ files }}/find-collisions.sh'
    - stateful: True

