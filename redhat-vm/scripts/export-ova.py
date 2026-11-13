#!/usr/bin/env python3
"""Convert a finalized QCOW2 disk into a portable OVF 1.0 `.ova` appliance.

Compatible out-of-the-box with:
  - VMware ESXi / vSphere 6.7, 7.x, 8.x
  - VMware Workstation / Fusion
  - Oracle VirtualBox 6.x / 7.x
"""

from __future__ import annotations

import argparse
import hashlib
import os
import subprocess
import sys
import tarfile
import tempfile
import xml.etree.ElementTree as ET
from pathlib import Path


OVF_TEMPLATE = """<?xml version="1.0" encoding="UTF-8"?>
<Envelope vmw:buildId="build-albaraka"
          xmlns="http://schemas.dmtf.org/ovf/envelope/1"
          xmlns:cim="http://schemas.dmtf.org/wbem/wscim/1/common"
          xmlns:ovf="http://schemas.dmtf.org/ovf/envelope/1"
          xmlns:rasd="http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/CIM_ResourceAllocationSettingData"
          xmlns:vmw="http://www.vmware.com/schema/ovf"
          xmlns:vssd="http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/CIM_VirtualSystemSettingData"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <References>
    <File ovf:href="{vmdk_name}" ovf:id="file1" ovf:size="{vmdk_size}"/>
  </References>
  <DiskSection>
    <Info>Virtual disk information</Info>
    <Disk ovf:capacity="{disk_gb}"
          ovf:capacityAllocationUnits="byte * 2^30"
          ovf:diskId="vmdisk1"
          ovf:fileRef="file1"
          ovf:format="http://www.vmware.com/interfaces/specifications/vmdk.html#streamOptimized"
          ovf:populatedSize="{vmdk_size}"/>
  </DiskSection>
  <NetworkSection>
    <Info>Logical networks used by the appliance</Info>
    <Network ovf:name="VM Network">
      <Description>Network carrying SSH (TCP 22) and Al Baraka Web Portal (TCP 8080)</Description>
    </Network>
  </NetworkSection>
  <VirtualSystem ovf:id="{vm_name}">
    <Info>Al Baraka Bank Tunisia — Governed AI Platform (Red Hat / Rocky Linux 9 Cloud Appliance)</Info>
    <Name>{vm_name}</Name>
    <ProductSection>
      <Info>Appliance metadata</Info>
      <Product>Al Baraka Bank Assistant &amp; RAGLab Appliance</Product>
      <Vendor>Ayari Farah — Al Baraka Bank Tunisia Internship</Vendor>
      <Version>1.0.0</Version>
      <FullVersion>Rocky Linux 9 (RHEL 9 compatible) + Pre-baked Docker Stack</FullVersion>
    </ProductSection>
    <AnnotationSection>
      <Info>Usage notes</Info>
      <Annotation>Al Baraka Bank Tunisia — Governed AI Platform (RAGLab + Bank Assistant).
After power-on, open http://&lt;VM-IP&gt;:8080 in your browser (displayed on the VM console).
Default VM SSH/Console user: albaraka / ChangeMe-AlBaraka-2026!
Default Web Admin login: admin@albaraka.tn / postgres</Annotation>
    </AnnotationSection>
    <OperatingSystemSection ovf:id="80" vmw:osType="rhel9_64Guest">
      <Info>Guest Operating System</Info>
      <Description>Red Hat Enterprise Linux 9 (64-bit)</Description>
    </OperatingSystemSection>
    <VirtualHardwareSection>
      <Info>Virtual hardware requirements</Info>
      <System>
        <vssd:ElementName>Virtual Hardware Family</vssd:ElementName>
        <vssd:InstanceID>0</vssd:InstanceID>
        <vssd:VirtualSystemIdentifier>{vm_name}</vssd:VirtualSystemIdentifier>
        <vssd:VirtualSystemType>vmx-14</vssd:VirtualSystemType>
      </System>
      <Item>
        <rasd:AllocationUnits>hertz * 10^6</rasd:AllocationUnits>
        <rasd:Description>Number of Virtual CPUs</rasd:Description>
        <rasd:ElementName>{cpus} virtual CPU(s)</rasd:ElementName>
        <rasd:InstanceID>1</rasd:InstanceID>
        <rasd:ResourceType>3</rasd:ResourceType>
        <rasd:VirtualQuantity>{cpus}</rasd:VirtualQuantity>
      </Item>
      <Item>
        <rasd:AllocationUnits>byte * 2^20</rasd:AllocationUnits>
        <rasd:Description>Memory Size</rasd:Description>
        <rasd:ElementName>{memory_mb}MB of memory</rasd:ElementName>
        <rasd:InstanceID>2</rasd:InstanceID>
        <rasd:ResourceType>4</rasd:ResourceType>
        <rasd:VirtualQuantity>{memory_mb}</rasd:VirtualQuantity>
      </Item>
      <Item>
        <rasd:Address>0</rasd:Address>
        <rasd:Description>SATA Controller</rasd:Description>
        <rasd:ElementName>sataController0</rasd:ElementName>
        <rasd:InstanceID>3</rasd:InstanceID>
        <rasd:ResourceSubType>AHCI</rasd:ResourceSubType>
        <rasd:ResourceType>20</rasd:ResourceType>
      </Item>
      <Item>
        <rasd:AddressOnParent>0</rasd:AddressOnParent>
        <rasd:ElementName>disk0</rasd:ElementName>
        <rasd:HostResource>ovf:/disk/vmdisk1</rasd:HostResource>
        <rasd:InstanceID>4</rasd:InstanceID>
        <rasd:Parent>3</rasd:Parent>
        <rasd:ResourceType>17</rasd:ResourceType>
      </Item>
      <Item>
        <rasd:AddressOnParent>7</rasd:AddressOnParent>
        <rasd:AutomaticAllocation>true</rasd:AutomaticAllocation>
        <rasd:Connection>VM Network</rasd:Connection>
        <rasd:Description>E1000 Ethernet adapter on &quot;VM Network&quot;</rasd:Description>
        <rasd:ElementName>ethernet0</rasd:ElementName>
        <rasd:InstanceID>5</rasd:InstanceID>
        <rasd:ResourceSubType>E1000</rasd:ResourceSubType>
        <rasd:ResourceType>10</rasd:ResourceType>
      </Item>
    </VirtualHardwareSection>
  </VirtualSystem>
</Envelope>
"""


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as fh:
        while True:
            chunk = fh.read(8 * 1024 * 1024)
            if not chunk:
                break
            digest.update(chunk)
    return digest.hexdigest()


def verify_ova(ova_path: Path, expected_base: str) -> None:
    with tarfile.open(ova_path, "r") as tf:
        names = [m.name for m in tf.getmembers()]
    expected = [
        f"{expected_base}.ovf",
        f"{expected_base}-disk1.vmdk",
        f"{expected_base}.mf",
    ]
    if names != expected:
        raise RuntimeError(f"Invalid OVA member ordering: got {names}, expected {expected}")


def main() -> int:
    parser = argparse.ArgumentParser(description="Export QCOW2 image to portable OVA.")
    parser.add_argument("--qcow2", required=True, type=Path, help="Input finalized qcow2 path")
    parser.add_argument("--out", required=True, type=Path, help="Output .ova file path")
    parser.add_argument("--name", default="albaraka-rhel9-appliance", help="Appliance base name")
    parser.add_argument("--cpus", type=int, default=2, help="Default vCPU count")
    parser.add_argument("--memory-mb", type=int, default=4096, help="Default RAM in MiB")
    parser.add_argument("--disk-gb", type=int, default=16, help="Virtual disk capacity in GiB")
    args = parser.parse_args()

    if not args.qcow2.is_file():
        print(f"Input qcow2 not found: {args.qcow2}", file=sys.stderr)
        return 1

    args.out.parent.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory(prefix="ova-export-", dir=str(args.out.parent)) as tmp:
        tmp_dir = Path(tmp)
        ovf_name = f"{args.name}.ovf"
        vmdk_name = f"{args.name}-disk1.vmdk"
        mf_name = f"{args.name}.mf"

        ovf_path = tmp_dir / ovf_name
        vmdk_path = tmp_dir / vmdk_name
        mf_path = tmp_dir / mf_name

        print(f"[OVA] Converting {args.qcow2.name} -> streamOptimized VMDK ({vmdk_name})...")
        subprocess.run(
            [
                "qemu-img",
                "convert",
                "-p",
                "-O",
                "vmdk",
                "-o",
                "subformat=streamOptimized,adapter_type=lsilogic",
                str(args.qcow2),
                str(vmdk_path),
            ],
            check=True,
        )

        vmdk_size = vmdk_path.stat().st_size
        ovf_xml = OVF_TEMPLATE.format(
            vm_name=args.name,
            vmdk_name=vmdk_name,
            vmdk_size=vmdk_size,
            disk_gb=args.disk_gb,
            cpus=args.cpus,
            memory_mb=args.memory_mb,
        )
        # Validate XML well-formedness before writing.
        ET.fromstring(ovf_xml)
        ovf_path.write_text(ovf_xml, encoding="utf-8")

        ovf_hash = sha256_file(ovf_path)
        vmdk_hash = sha256_file(vmdk_path)
        mf_path.write_text(
            f"SHA256({ovf_name})= {ovf_hash}\nSHA256({vmdk_name})= {vmdk_hash}\n",
            encoding="utf-8",
        )

        print(f"[OVA] Packing OVF 1.0 archive -> {args.out} ...")
        with tarfile.open(args.out, mode="w", format=tarfile.USTAR_FORMAT) as tar:
            for item_path in (ovf_path, vmdk_path, mf_path):
                info = tar.gettarinfo(str(item_path), arcname=item_path.name)
                info.uid = 0
                info.gid = 0
                info.uname = "root"
                info.gname = "root"
                info.mode = 0o644
                with item_path.open("rb") as fh:
                    tar.addfile(info, fh)

    os.chmod(args.out, 0o644)
    verify_ova(args.out, args.name)
    size_mb = args.out.stat().st_size / (1024 * 1024)
    print(f"[OVA] Verified {args.out.name} ({size_mb:.1f} MiB)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
