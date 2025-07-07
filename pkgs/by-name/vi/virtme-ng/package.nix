{ lib
, makeWrapper
, fetchFromGitHub
, bash
, busybox
, systemd
, python3
, socat
, virtiofsd
, file
, qemu
 }:

python3.pkgs.buildPythonApplication rec {
  pname = "virtme-ng";
  version = "1.36";

  src = fetchFromGitHub {
    owner = "arighi";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-/dO7BAWLsmL/EVO/9Ja8h7MuYTwOxBav3iHQkegyyoY=";
  };

  pyproject = true;
  build-system = with python3.pkgs; [ setuptools ];

  nativeBuildInputs = [ makeWrapper ];

  propagatedBuildInputs = with python3.pkgs; [
    argcomplete
    argparse-manpage
    requests
    setuptools
  ] ++ [
    file
    qemu
    socat
  ];

  postFixup = ''
    mv $out/lib/python3.13/site-packages/virtme/guest/virtme-init{,.unwrapped}

    substituteInPlace $out/lib/python3.13/site-packages/virtme/guest/virtme-init.unwrapped \
      --replace-fail "/bin/bash" "${bash}/bin/bash" \
      --replace-fail "export PATH=" "export PATH=\$PATH:" \
      --replace-fail "udevd=\$(command -v udevd)" "udevd=${systemd}/lib/systemd/systemd-udevd" \
      --replace-fail "setsid bash -c \"su " "setsid bash -c \"su -s ${bash}/bin/bash "

    makeWrapper $out/lib/python3.13/site-packages/virtme/guest/virtme-init{.unwrapped,} \
      --prefix PATH : ${lib.makeBinPath [
          bash
          busybox # slimmed down coreutils
          systemd # udevadm
          socat # for terminal (maybe)
          virtiofsd
      ]}
  '';
}
