const { assert } = require('chai')

const Eathereum = artifacts.require('./Eathereum.sol')
const RewardPool = artifacts.require('./RewardPool.sol')
const EAT = artifacts.require('./EAT.sol')

const toWei = async value => await web3.utils.toWei(value, 'ether')

require('chai')
  .use(require('chai-as-promised'))
  .should()

contract(Eathereum, ([owner, player, playerTwo, dev, playerThree]) => {
    let eathereum,
    eatToken,
    rewardPool

  describe('Eathereum', async () => {
    const _name = "Player"
    const _namePlayerTwo = "PlayerTwo"
    const initialRewardPoolEat = await toWei('10000')
    const eatReward = await toWei('1')
    const eatAwardLimit = await toWei('100000')
    
    const _amount = await toWei('1.5')
    const _amountLess = await toWei('1')
    const _smallAmount = await toWei('0.1')

    it('creates player', async () => {
        eathereum = await Eathereum.deployed(eatReward, eatReward, eatAwardLimit, { from: owner })
        eatToken = await EAT.deployed({ from: owner })
        rewardPool = await RewardPool.deployed(eatToken.address, dev, { from: owner })
        eatToken.mint(rewardPool.address ,initialRewardPoolEat)
        rewardPool.transferOwnership(eathereum.address, { from: owner })
        await eathereum.setRewardPoolAddress(rewardPool.address, { from: owner })    

        createdPlayer = await eathereum.createPlayer(_name, { from: player, value: _amountLess })
        await eathereum.createPlayer(_namePlayerTwo, { from: playerTwo, value: _amount })
        const event = createdPlayer.logs[0].args
        const rewardPoolBalance = await eatToken.balanceOf(rewardPool.address)
        const playersPlayed = await eathereum.playersPlayed()

        console.log(rewardPoolBalance.toString())
        assert.equal(event.name, _name, 'name is correct')
        assert.isTrue(event.isPlaying, 'isPlaying is correct')
        assert.equal(event.amount.toString(), _amountLess, 'amount is correct')
        assert.equal(playersPlayed, 2, 'players played is correct')
    })


    it('should eat player - eater has less amount then eaten', async () => {
        await eatPlayerCheck(owner, player, playerTwo, eathereum)
        const eatRewardPool = await rewardPool.rewards(player)
        assert.equal(eatRewardPool.toString(), eatReward, 'user has eat reward awaiting in pool')
        await rewardPool.withdraw({ from: player })
        const eatBalance = await eatToken.balanceOf(player)
        const emptyPlayerRewardPoolBalance = await rewardPool.rewards(player)
        assert.equal(eatBalance.toString(), eatReward, 'user withdrew his rewards from pool')
        assert.equal(
            emptyPlayerRewardPoolBalance.toString(), 
            '0', 
            'user cashed out on his reward, rewards are now 0'
        )
    })

    it('should eat player - no eat will be distributed', async () => {
        await eathereum.createPlayer(_name, { from: playerThree, value: _smallAmount })
        await eathereum.createPlayer(_namePlayerTwo, { from: playerTwo, value: _smallAmount })
        await eatPlayerCheck(owner, playerTwo, playerThree, eathereum)
        const emptyPlayerRewardPoolBalance = await rewardPool.rewards(playerTwo)
        assert.equal(
            emptyPlayerRewardPoolBalance.toString(), 
            '0', 
            'player two has 0 rewards in pool'
        )
        rewardPool.withdraw({ from: playerTwo }).should.be.rejected

    })

    it('should eat player - eater has more amount then eaten', async () => {

      await eatPlayerCheck(owner, player, playerTwo, eathereum)
    })

    it('should increase owner balance', async () => {
      let ownerOldBalance, 
      ownerNewBalance

      ownerOldBalance = await getBalance(owner)
      await eathereum.pullFees({ from: owner})
      ownerNewBalance = await getBalance(owner)
      assert.isAbove(ownerNewBalance, ownerOldBalance, 'owner balance has increased')
    })

    it('should let player leave', async () => {
        let gas = await toWei('0.00000001')
        let playerOldBalance, 
        playerNewBalance, 
        ownerOldBalance, 
        ownerNewBalance
        playerOldBalance = await getBalance(player)
        ownerOldBalance = await getBalance(owner)
        await eathereum.playerLeave(player, gas, { from: owner })
        await eathereum.pullFees({ from: owner})

        playerNewBalance = await getBalance(player)
        ownerNewBalance = await getBalance(owner)
        const playerTwoEathereum = await eathereum.players(playerTwo)
        assert.isFalse(playerTwoEathereum.isPlaying, 'player two isnt playing')
        assert.equal(
            playerTwoEathereum.amount.toString(), 
            '0', 
            'player two amount needs to be equal to 0'
        )
        assert.isAbove(playerNewBalance, playerOldBalance, 'player one balance has increased')
        assert.isAbove(ownerNewBalance, ownerOldBalance, 'owner balance has increased')
    })

    it('should transfer funds to owner when player disconnects', async () => {
        let playerOldBalance, 
        playerNewBalance, 
        ownerOldBalance, 
        ownerNewBalance
        await eathereum.createPlayer(_namePlayerTwo, { from: playerTwo, value: _smallAmount })
        playerOldBalance = await getBalance(playerTwo)
        ownerOldBalance = await getBalance(owner)
        await eathereum.playerDisconnect(playerTwo, { from: owner })
        await eathereum.pullFees({ from: owner})
        playerNewBalance = await getBalance(playerTwo)
        ownerNewBalance = await getBalance(owner)
        assert.equal(playerNewBalance, playerOldBalance, 'players balance is the same')
        assert.isAbove(ownerNewBalance, ownerOldBalance, 'owner balance has increased')
    })
   
  })
})

const getBalance = async (address) => parseFloat(
    (web3.utils.fromWei((await web3.eth.getBalance(address)), 'ether'))
)

const eatPlayerCheck = async (owner, player, playerTwo, eathereum) => {
    let gas = await toWei('0.00000001')
    let playerOldBalance, 
    playerNewBalance
    playerOldBalance = await getBalance(player)
    await eathereum.playerEaten(player, playerTwo, gas, {from: owner})
    playerNewBalance = await getBalance(player)
    const playerInfo = await eathereum.players(playerTwo)
    assert.equal(playerInfo.amount.toString(), '0', 'player two amount needs to be equal to 0')
    assert.isFalse(playerInfo.isPlaying, 'player two is no longer playing')
    assert.isAbove(playerNewBalance, playerOldBalance, 'player one balance has increased')

}

