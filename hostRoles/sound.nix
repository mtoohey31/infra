{ ... }: {
  sound.enable = true;
  # TODO: switch to pipewire (and remove pulsemixer from gui user role)
  hardware.pulseaudio.enable = true;
}
