{
  lib,
  rustPlatform,
  fetchCrate,
  llvmPackages,
  pkg-config,
  elfutils,
  zlib,
  zstd,
  libseccomp,
}:

rustPlatform.buildRustPackage rec {
  pname = "scx_lavd";
  version = "1.0.16";

  src = fetchCrate {
    inherit pname version;
    hash = "sha256-vh5MYFRblwOP6tD9s1q57qVipenc0oWyHpFmSqYvNh0=";
  };

  cargoHash = "sha256-hIy9UXPPfo3QGmCfU97yvVEHGB7jWxymXc8Ny/2SVEI=";

  nativeBuildInputs = [
    pkg-config
    rustPlatform.bindgenHook
  ];

  buildInputs = [
    elfutils
    zlib
    zstd
    libseccomp
  ];

  env = {
    BPF_CLANG = lib.getExe llvmPackages.clang;
    RUSTFLAGS = lib.concatStringsSep " " [
      "-C relocation-model=pic"
      "-C link-args=-lelf"
      "-C link-args=-lz"
      "-C link-args=-lzstd"
    ];
  };

  hardeningDisable = [
    "stackprotector"
    "zerocallusedregs"
  ];

  meta = with lib; {
    description = "Latency-criticality Aware Virtual Deadline (LAVD) scheduler";
    longDescription = ''
      scx_lavd is a BPF scheduler that implements a Latency-criticality Aware
      Virtual Deadline (LAVD) scheduling algorithm. It is designed to improve
      interactivity and reduce stuttering while playing games on Linux.

      ::: {.note}
      Sched-ext schedulers are only available on kernels version 6.12 or later.
      It is recommended to use the latest kernel for the best compatibility.
      :::
    '';
    homepage = "https://github.com/sched-ext/scx";
    license = licenses.gpl2Only;
    maintainers = with maintainers; [ ];
    platforms = platforms.linux;
  };
}