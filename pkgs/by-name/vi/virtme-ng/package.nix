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
  version = "1.33";

  src = fetchFromGitHub {
    owner = "arighi";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-JPcjOHS0rAbzNGVUMnMJKG/WzLXBejWF6oCRoDNXFRI=";
  };

  nativeBuildInputs = [ makeWrapper ];

  propagatedBuildInputs = with python3.pkgs; [
    argcomplete
    requests
    setuptools
  ] ++ [
    file
    qemu
    socat
  ];

  postFixup = ''
    mv $out/lib/python3.12/site-packages/virtme/guest/virtme-init{,.unwrapped}

    substituteInPlace $out/lib/python3.12/site-packages/virtme/guest/virtme-init.unwrapped \
      --replace-fail "/bin/bash" "${bash}/bin/bash" \
      --replace-fail "export PATH=" "export PATH=\$PATH:" \
      --replace-fail "udevd=\`which udevd\`" "udevd=${systemd}/lib/systemd/systemd-udevd" \
      --replace-fail "setsid bash -c \"su " "setsid bash -c \"su -s ${bash}/bin/bash "

    makeWrapper $out/lib/python3.12/site-packages/virtme/guest/virtme-init{.unwrapped,} \
      --prefix PATH : ${lib.makeBinPath [
          bash
          busybox # slimmed down coreutils
          systemd # udevadm
          socat # for terminal (maybe)
          virtiofsd
      ]}
  '';
}
