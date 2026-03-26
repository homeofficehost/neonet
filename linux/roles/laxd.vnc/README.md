Role Name
=========

Installs and enabled a VNC server on the target host

Requirements
------------

A vncpasswd file (probably created using vncpasswd) is required to set up authentication. Without this, the target user will need to log in to the host via a method other than VNC and run vncpasswd

Role Variables
--------------

vnc_package_name - Package to install to provide a vncserver implementation
user - User to setup as the user running the vnc server
vnc_config_dir - Location of config dir for VNC, usually .vnc in the user's home directory
vnc_passwd_file OPTIONAL - will be copied to vnc_config_dir/passwd

Example Playbook
----------------

    - hosts: all
      roles:
        - laxd.ansible-vnc

License
-------

BSD
