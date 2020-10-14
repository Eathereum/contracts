const { expectRevert, time } = require('@openzeppelin/test-helpers')
const { advanceBlock } = require('@openzeppelin/test-helpers/src/time')
const { assert } = require('chai')
const EAT = artifacts.require('./EAT.sol')
const Farm = artifacts.require('./Farm.sol')
const MockERC20 = artifacts.require('./DummyERC20.sol')
require('chai')
  .use(require('chai-as-promised'))
  .should()
contract('Farm', async ([alice, bob, carol, dev, minter, smith, lil]) => {

    it('should deploy contract correctly', async () => {
        const limit = '300000000000000000000000'
        let eatToken = await EAT.deployed(limit, { from: alice })
        assert.equal(await eatToken.name(), 'Eathereum')
        assert.equal(await eatToken.symbol(), 'EAT')
        assert.equal(await eatToken.limit(), limit)
        eatToken.mint(bob, '300000000000000000000000', {from: alice})
        eatToken.mint(bob, '1', {from: alice}).should.be.rejected
    }) 
})

function getBalance(token, address) {
  return new Promise(async resolve => {
    resolve((await token.balanceOf(address)).toString())
  })
}
const toWei = async value => await web3.utils.toWei(value, 'ether')
const fromWei = async value => await web3.utils.fromWei(value, 'ether')