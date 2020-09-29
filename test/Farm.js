// const { expectRevert, time } = require('@openzeppelin/test-helpers')
// const { advanceBlock } = require('@openzeppelin/test-helpers/src/time')
// const { assert } = require('chai')
// const EAT = artifacts.require('./EAT.sol')
// const Farm = artifacts.require('./Farm.sol')
// const MockERC20 = artifacts.require('./DummyERC20.sol')
// require('chai')
//   .use(require('chai-as-promised'))
//   .should()
// contract('Farm', async ([alice, bob, carol, dev, minter, smith, lil]) => {

//     it('should set correct state variables', async () => {
//         let eatToken = await EAT.deployed({ from: alice })
//         let farm = await Farm.deployed(dev, '650000000000000000', '0', '0', { from: alice })
//         const eater_amount = await toWei('200000')
//         eatToken.mint(farm.address, eater_amount, { from: alice })
//         await farm.setEatAddress(eatToken.address, { from: dev })
//         const dev_address = await farm.dev_address()
//         const owner = await eatToken.owner()
//         const maker_balance = await eatToken.balanceOf(farm.address)
//         console.log(maker_balance.toString())
//         assert.equal(await farm.eat(), eatToken.address, 'eat')
//         assert.equal(dev_address, dev, 'dev address equal to dev')
//         assert.equal(owner, alice, 'owner')
//     })

//     it('should allow only dev to update dev_address', async () => {
//       let farm = await Farm.deployed(dev, '650000000000000000', '0', '0', { from: alice })
//       await farm.updateDevAddress(alice, { from: alice }).should.be.rejectedWith('Not dev address')
//       await farm.updateDevAddress(alice, { from: dev })
//       let dev_address = await farm.dev_address()
//       assert.equal(dev_address, alice, 'new dev address')
//       await farm.updateDevAddress(dev, { from: alice })
//       dev_address = await farm.dev_address()
//       assert.equal(dev_address, dev, 'new dev address')
//     })



//   it('should let user withdraw rewards when lock period is over', async () => {
//     const first_reward_num = 0.13
//     const amount = await toWei('50000')
//     const init_deposit = await toWei('100')
//     const bob_first_withdraw = await toWei('0.195')
//     const first_reward = await toWei(first_reward_num.toString())
//     const half_reward = await toWei((first_reward_num / 2).toString())
//     const third_reward = await toWei((first_reward_num * 3).toString())

//     let eatToken = await EAT.deployed({ from: alice })
//     let farm = await Farm.deployed(dev, '650000000000000000', '0', '0', { from: alice })
//     const tokens = await Promise.all([0,1,2,3,4].map(async token => {
//       const lp = await MockERC20.new('LPToken', 'LP' + token, await toWei('1000000'), { from: minter })
//       await lp.transfer(bob, amount, { from: minter })
//       await lp.transfer(carol, amount, { from: minter })
//       await lp.transfer(smith, amount, { from: minter })
//       await lp.approve(farm.address, amount, { from: bob })
//       await lp.approve(farm.address, amount, { from: carol })
//       await lp.approve(farm.address, amount, { from: smith })
//       return lp
//     }))
//     await Promise.all([
//       tokens.forEach(async token => {
//         await farm.addPool(first_reward, token.address, false);
//       })]
//     )
//     await farm.deposit(2, init_deposit, {from: smith})
//     await farm.deposit(0, init_deposit, { from: bob })
//     await farm.deposit(1, init_deposit, { from: carol })
//     assert.equal(await pendingEat(farm, bob, 0), first_reward, 'bob first reward')
//     await farm.withdraw(0, first_reward, { from: bob }).should.be.rejectedWith('EAT currently locked')
//     assert.equal(await pendingEat(farm, carol, 1), first_reward, 'carol first reward')
//     assert.equal(await pendingEat(farm, carol, 0), '0', 'carol has no reward in different pool')
//     await farm.deposit(1, init_deposit, { from: bob })
//     assert.equal(await pendingEat(farm, bob, 0), third_reward, 'bob third 1st pool reward')
//     await time.advanceBlock()
//     assert.equal(await pendingEat(farm, bob, 1), half_reward, 'bob first 2nd pool reward')
//     await unlockPool(farm, 1, dev, alice)
//     const carol_pending_reward = await pendingEat(farm, carol, 1)
//     await farm.withdraw(1, first_reward, { from: bob })
//     assert.equal(await pendingEat(farm, bob, 1), '0', 'bob withdrew rewards, has no rewards in 2nd pool')
//     await farm.unlockPool(0, {from: bob}).should.be.rejectedWith('Not dev address')
//     assert.equal(bob_first_withdraw, await getBalance(eatToken, bob), 'bob has 0.195 eat')
//     assert.equal(carol_pending_reward, await pendingEat(farm, carol, 1), 'carols reward should stay the same as pool has been unlocked')

//   })

//   it('should let user withdraw their lp tokens',  async () => {
//     let eatToken = await EAT.deployed({ from: alice })
//     let farm = await Farm.deployed(dev, '650000000000000000', '0', '0', { from: alice })
//     const smith_pending = await (fromWei(await pendingEat(farm, smith, 2)))

//     assert.isAbove(parseFloat(smith_pending), 0, 'smith has reward pending in pool 3')
//     const smith_deposit_amount = (await farm.userInfo(2, smith)).amount.toString()
//     await farm.withdrawLPTokens(2, smith_deposit_amount, { from: smith })
//     assert.equal(await getBalance(eatToken, smith), '0', 'pool is locked, no eat was rewarded to smith')
//     assert.equal(await pendingEat(farm, smith, 2), '0', 'smith lost all pending rewards')
//   })

//   it('should unlock all pools and create new pool', async () => {
//     const first_reward_num = 0.13
//     const amount = await toWei('50000')
//     const init_deposit = await toWei('100')
//     const first_reward = await toWei(first_reward_num.toString())
//     const new_pool_first_reward = await toWei((first_reward_num*5).toString())
//     const eat_ether_lp = await MockERC20
//     .new(
//       'EAT-ETH-LP', 
//       'LP', 
//       await toWei('1000000'), 
//       { from: minter }
//     )
//     await eat_ether_lp.transfer(bob, amount, { from: minter })
//     let eatToken = await EAT.deployed({ from: alice })
//     let farm = await Farm.deployed(dev, '650000000000000000', '0', '0', { from: alice })
//     await farm
//     .updateEatPerBlock(amount, { from: bob })
//     .should.be.rejected
//     await farm.addPool(first_reward, eat_ether_lp.address, false)
//     await unlockPool(farm, 0, dev, alice)
//     await unlockPool(farm, 2, dev, alice)
//     await unlockPool(farm, 3, dev, alice)
//     await unlockPool(farm, 4, dev, alice)
//     const bob_withdraw_amount = await pendingEat(farm, bob, 0)
//     const bobs_old_balance = parseFloat((await fromWei((await getBalance(eatToken, bob)))))
//     await farm.withdraw(0, bob_withdraw_amount, { from: bob })
//     const bobs_new_balance = parseFloat((await fromWei((await getBalance(eatToken, bob)))))
//     assert.isAbove(bobs_new_balance, bobs_old_balance, 'bob is able to withdraw his rewards from unlocked pool')
//     await eat_ether_lp.approve(farm.address, '112831892381923819238191931', { from: bob })
//     await farm.deposit(5, init_deposit, { from: bob })
//     await time.advanceBlock()
//     const bob_first_block_reward = (await pendingEat(farm ,bob , 5))
//     assert.equal(bob_first_block_reward.toString(), new_pool_first_reward)
//   })

//   it(`should let only dev to reduce eat per block`, async () => {
//     let eatToken = await EAT.deployed({ from: alice })
//     let farm = await Farm.deployed(dev, '650000000000000000', '0', '0', { from: alice })
//     await farm.updateEatPerBlock(await toWei('50000000'), { from: bob }).should.be.rejected
//     await farm.updateEatPerBlock(await toWei('0.13'), { from: dev })
//     const eat_per_block = (await farm.eatPerBlock()).toString()
//     assert.equal(eat_per_block, await toWei('0.13'), 'eatperblock is now changeds')
    
//   })
// })

// async function unlockPool(farm, pool, dev, alice) {
//   await farm.unlockPool(pool, {from: dev})
//   await farm.set(pool, 0, true, {from:alice}) // upon unlocking a pool it is to be closed
  
// }

// async function pendingEat(farm, address, pool) {
//   return (await farm.pendingEat(pool, address)).toString()
// }

// function getBalance(token, address) {
//   return new Promise(async resolve => {
//     resolve((await token.balanceOf(address)).toString())
//   })
// }

// const toWei = async value => await web3.utils.toWei(value, 'ether')
// const fromWei = async value => await web3.utils.fromWei(value, 'ether')