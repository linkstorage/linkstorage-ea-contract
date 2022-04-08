import { ethers } from 'hardhat';

async function main() {
  const Linkstorage = await ethers.getContractFactory('Linkstorage');
  const linkstorage = await Linkstorage.deploy();

  await linkstorage.deployed();

  console.log('Linkstorage deployed to:', linkstorage.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
