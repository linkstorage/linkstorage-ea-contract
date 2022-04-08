import { expect } from 'chai';
import { ethers } from 'hardhat';

describe('Linkstorage', function () {
  it('Should return the new greeting once it\'s changed', async function () {
    const Linkstorage = await ethers.getContractFactory('Linkstorage');
    const linkstorage = await Linkstorage.deploy();
    await linkstorage.deployed();

    const changeStatesTx = await linkstorage.stateUpdateAndSaveToIPFS('id001', 'val1', 'val2', 'val3');
    await changeStatesTx.wait();
    expect(changeStatesTx.hash).not.null;
  });
});
