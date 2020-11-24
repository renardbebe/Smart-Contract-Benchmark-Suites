 

pragma solidity ^0.4.21;

library BWUtility {
    
     


     
    function ceil(uint _amount, uint _multiple) pure public returns (uint) {
        return ((_amount + _multiple - 1) / _multiple) * _multiple;
    }

     
     
     
     
     
     
    function isAdjacent(uint8 _x1, uint8 _y1, uint8 _x2, uint8 _y2) pure public returns (bool) {
        return ((_x1 == _x2 &&      (_y2 - _y1 == 1 || _y1 - _y2 == 1))) ||       
               ((_y1 == _y2 &&      (_x2 - _x1 == 1 || _x1 - _x2 == 1))) ||       
               ((_x2 - _x1 == 1 &&  (_y2 - _y1 == 1 || _y1 - _y2 == 1))) ||       
               ((_x1 - _x2 == 1 &&  (_y2 - _y1 == 1 || _y1 - _y2 == 1)));         
    }

     
    function toTileId(uint8 _x, uint8 _y) pure public returns (uint16) {
        return uint16(_x) << 8 | uint16(_y);
    }

     
    function fromTileId(uint16 _tileId) pure public returns (uint8, uint8) {
        uint8 y = uint8(_tileId);
        uint8 x = uint8(_tileId >> 8);
        return (x, y);
    }
    
    function getBoostFromTile(address _claimer, address _attacker, address _defender, uint _blockValue) pure public returns (uint, uint) {
        if (_claimer == _attacker) {
            return (_blockValue, 0);
        } else if (_claimer == _defender) {
            return (0, _blockValue);
        }
    }
}






interface ERC20I {
    function transfer(address _recipient, uint256 _amount) external returns (bool);
    function balanceOf(address _holder) external view returns (uint256);
}


contract BWService {
    using SafeMath for uint256;
    address private owner;
    address private bw;
    address private bwMarket;
    BWData private bwData;
    uint private seed = 42;
    uint private WITHDRAW_FEE = 5;  
    uint private ATTACK_FEE = 5;  
    uint private ATTACK_BOOST_CAP = 300;  
    uint private DEFEND_BOOST_CAP = 300;  
    uint private ATTACK_BOOST_MULTIPLIER = 100;  
    uint private DEFEND_BOOST_MULTIPLIER = 100;  
    mapping (uint16 => address) private localGames;
    
    modifier isOwner {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }  

    modifier isValidCaller {
        if (msg.sender != bw && msg.sender != bwMarket) {
            revert();
        }
        _;
    }

    event TileClaimed(uint16 tileId, address newClaimer, uint priceInWei, uint creationTime);
    event TileFortified(uint16 tileId, address claimer, uint addedValueInWei, uint priceInWei, uint fortifyTime);  
    event TileAttackedSuccessfully(uint16 tileId, address attacker, uint attackAmount, uint totalAttackAmount, address defender, uint defendAmount, uint totalDefendAmount, uint attackRoll, uint attackTime);  
    event TileDefendedSuccessfully(uint16 tileId, address attacker, uint attackAmount, uint totalAttackAmount, address defender, uint defendAmount, uint totalDefendAmount, uint attackRoll, uint defendTime);  
    event BlockValueMoved(uint16 sourceTileId, uint16 destTileId, address owner, uint movedBlockValue, uint postSourceValue, uint postDestValue, uint moveTime);  
    event UserBattleValueUpdated(address userAddress, uint battleValue, bool isWithdraw);

     
    constructor(address _bwData) public {
        bwData = BWData(_bwData);
        owner = msg.sender;
    }

     
    function () payable public {
        revert();
    }

     
    function kill() public isOwner {
        selfdestruct(owner);
    }

    function setValidBwCaller(address _bw) public isOwner {
        bw = _bw;
    }
    
    function setValidBwMarketCaller(address _bwMarket) public isOwner {
        bwMarket = _bwMarket;
    }

    function setWithdrawFee(uint _feePercentage) public isOwner {
        WITHDRAW_FEE = _feePercentage;
    }

    function setAttackFee(uint _feePercentage) public isOwner {
        ATTACK_FEE = _feePercentage;
    }

    function setAttackBoostMultipler(uint _multiplierPercentage) public isOwner {
        ATTACK_BOOST_MULTIPLIER = _multiplierPercentage;
    }

    function setDefendBoostMultiplier(uint _multiplierPercentage) public isOwner {
        DEFEND_BOOST_MULTIPLIER = _multiplierPercentage;
    }

    function setAttackBoostCap(uint _capPercentage) public isOwner {
        ATTACK_BOOST_CAP = _capPercentage;
    }

    function setDefendBoostCap(uint _capPercentage) public isOwner {
        DEFEND_BOOST_CAP = _capPercentage;
    }

     
     
     
     
    function storeInitialClaim(address _msgSender, uint16[] _claimedTileIds, uint _claimAmount, bool _useBattleValue) public isValidCaller {
        uint tileCount = _claimedTileIds.length;
        require(tileCount > 0);
        require(_claimAmount >= 1 finney * tileCount);  
        require(_claimAmount % tileCount == 0);  

        uint valuePerBlockInWei = _claimAmount.div(tileCount);  
        require(valuePerBlockInWei >= 5 finney);

        if (_useBattleValue) {
            subUserBattleValue(_msgSender, _claimAmount, false);  
        }

        addGlobalBlockValueBalance(_claimAmount);

        uint16 tileId;
        bool isNewTile;
        for (uint16 i = 0; i < tileCount; i++) {
            tileId = _claimedTileIds[i];
            isNewTile = bwData.isNewTile(tileId);  
            require(isNewTile);  

             
            emit TileClaimed(tileId, _msgSender, valuePerBlockInWei, block.timestamp);

             
            bwData.storeClaim(tileId, _msgSender, valuePerBlockInWei);
        }
    }

    function fortifyClaims(address _msgSender, uint16[] _claimedTileIds, uint _fortifyAmount, bool _useBattleValue) public isValidCaller {
        uint tileCount = _claimedTileIds.length;
        require(tileCount > 0);

        address(this).balance.add(_fortifyAmount);  
        require(_fortifyAmount % tileCount == 0);  
        uint addedValuePerTileInWei = _fortifyAmount.div(tileCount);  
        require(_fortifyAmount >= 1 finney * tileCount);  

        address claimer;
        uint blockValue;
        for (uint16 i = 0; i < tileCount; i++) {
            (claimer, blockValue) = bwData.getTileClaimerAndBlockValue(_claimedTileIds[i]);
            require(claimer != 0);  
            require(claimer == _msgSender);  

            if (_useBattleValue) {
                subUserBattleValue(_msgSender, addedValuePerTileInWei, false);
            }
            
            fortifyClaim(_msgSender, _claimedTileIds[i], addedValuePerTileInWei);
        }
    }

    function fortifyClaim(address _msgSender, uint16 _claimedTileId, uint _fortifyAmount) private {
        uint blockValue;
        uint sellPrice;
        (blockValue, sellPrice) = bwData.getCurrentBlockValueAndSellPriceForTile(_claimedTileId);
        uint updatedBlockValue = blockValue.add(_fortifyAmount);
         
        emit TileFortified(_claimedTileId, _msgSender, _fortifyAmount, updatedBlockValue, block.timestamp);
        
         
        bwData.updateTileBlockValue(_claimedTileId, updatedBlockValue);

         
        addGlobalBlockValueBalance(_fortifyAmount);
    }

     
     
     
     
     
    function random(uint _upper) private returns (uint)  {
        seed = uint(keccak256(blockhash(block.number - 1), block.coinbase, block.timestamp, seed, address(0x3f5CE5FBFe3E9af3971dD833D26bA9b5C936f0bE).balance));
        return seed % _upper;
    }

     
     
    function attackTile(address _msgSender, uint16 _tileId, uint _attackAmount, bool _useBattleValue) public isValidCaller {
        require(_attackAmount >= 1 finney);          
        require(_attackAmount % 1 finney == 0);

        address claimer;
        uint blockValue;
        (claimer, blockValue) = bwData.getTileClaimerAndBlockValue(_tileId);
        
        require(claimer != 0);  
        require(claimer != _msgSender);  
        require(claimer != owner);  

         
         
         
        uint attackBoost;
        uint defendBoost;
        (attackBoost, defendBoost) = bwData.calculateBattleBoost(_tileId, _msgSender, claimer);

         
        attackBoost = attackBoost.mul(ATTACK_BOOST_MULTIPLIER).div(100);
        defendBoost = defendBoost.mul(DEFEND_BOOST_MULTIPLIER).div(100);
        
         
        if (attackBoost > _attackAmount.mul(ATTACK_BOOST_CAP).div(100)) {
            attackBoost = _attackAmount.mul(ATTACK_BOOST_CAP).div(100);
        }
        if (defendBoost > blockValue.mul(DEFEND_BOOST_CAP).div(100)) {
            defendBoost = blockValue.mul(DEFEND_BOOST_CAP).div(100);
        }

        uint totalAttackAmount = _attackAmount.add(attackBoost);
        uint totalDefendAmount = blockValue.add(defendBoost);

         
        require(totalAttackAmount.div(10) <= totalDefendAmount);  
        require(totalAttackAmount >= totalDefendAmount.div(10));  

        uint attackFeeAmount = _attackAmount.mul(ATTACK_FEE).div(100);
        uint attackAmountAfterFee = _attackAmount.sub(attackFeeAmount);
        
        updateFeeBalance(attackFeeAmount);

         
        uint attackRoll = random(totalAttackAmount.add(totalDefendAmount));  

         
        if (attackRoll > totalDefendAmount) {
             
            bwData.setClaimerForTile(_tileId, _msgSender);

             
            if (_useBattleValue) {
                 
                addUserBattleValue(_msgSender, attackAmountAfterFee);  
                subUserBattleValue(_msgSender, attackAmountAfterFee, false);
            } else {
                addUserBattleValue(_msgSender, attackAmountAfterFee);  
            }
            addUserBattleValue(claimer, 0);

            bwData.updateTileTimeStamp(_tileId);
             
            emit TileAttackedSuccessfully(_tileId, _msgSender, attackAmountAfterFee, totalAttackAmount, claimer, blockValue, totalDefendAmount, attackRoll, block.timestamp);
        } else {
            bwData.setClaimerForTile(_tileId, claimer);  
             
            if (_useBattleValue) {
                subUserBattleValue(_msgSender, attackAmountAfterFee, false);  
            }
            addUserBattleValue(claimer, attackAmountAfterFee);  
            
             
            emit TileDefendedSuccessfully(_tileId, _msgSender, attackAmountAfterFee, totalAttackAmount, claimer, blockValue, totalDefendAmount, attackRoll, block.timestamp);
        }
    }

    function updateFeeBalance(uint attackFeeAmount) private {
        uint feeBalance = bwData.getFeeBalance();
        feeBalance = feeBalance.add(attackFeeAmount);
        bwData.setFeeBalance(feeBalance);
    }

    function moveBlockValue(address _msgSender, uint8 _xSource, uint8 _ySource, uint8 _xDest, uint8 _yDest, uint _moveAmount) public isValidCaller {
        uint16 sourceTileId = BWUtility.toTileId(_xSource, _ySource);
        uint16 destTileId = BWUtility.toTileId(_xDest, _yDest);

        address sourceTileClaimer;
        address destTileClaimer;
        uint sourceTileBlockValue;
        uint destTileBlockValue;
        (sourceTileClaimer, sourceTileBlockValue) = bwData.getTileClaimerAndBlockValue(sourceTileId);
        (destTileClaimer, destTileBlockValue) = bwData.getTileClaimerAndBlockValue(destTileId);

        uint newBlockValue = sourceTileBlockValue.sub(_moveAmount);
         
        require(newBlockValue == 0 || newBlockValue >= 5 finney);

        require(sourceTileClaimer == _msgSender);
        require(destTileClaimer == _msgSender);
        require(_moveAmount >= 1 finney);  
        require(_moveAmount % 1 finney == 0);  
         
        
        require(BWUtility.isAdjacent(_xSource, _ySource, _xDest, _yDest));

        sourceTileBlockValue = sourceTileBlockValue.sub(_moveAmount);
        destTileBlockValue = destTileBlockValue.add(_moveAmount);

         
        if (sourceTileBlockValue == 0) {
            bwData.deleteTile(sourceTileId);
        } else {
            bwData.updateTileBlockValue(sourceTileId, sourceTileBlockValue);
            bwData.deleteOffer(sourceTileId);  
        }

        bwData.updateTileBlockValue(destTileId, destTileBlockValue);
        bwData.deleteOffer(destTileId);    
        emit BlockValueMoved(sourceTileId, destTileId, _msgSender, _moveAmount, sourceTileBlockValue, destTileBlockValue, block.timestamp);        
    }

    function verifyAmount(address _msgSender, uint _msgValue, uint _amount, bool _useBattleValue) view public isValidCaller {
        if (_useBattleValue) {
            require(_msgValue == 0);
            require(bwData.getUserBattleValue(_msgSender) >= _amount);
        } else {
            require(_amount == _msgValue);
        }
    }

    function setLocalGame(uint16 _tileId, address localGameAddress) public isOwner {
        localGames[_tileId] = localGameAddress;
    }

    function getLocalGame(uint16 _tileId) view public isValidCaller returns (address) {
        return localGames[_tileId];
    }

     
    function withdrawBattleValue(address msgSender, uint _battleValueInWei) public isValidCaller returns (uint) {
         
        uint fee = _battleValueInWei.mul(WITHDRAW_FEE).div(100);  
        uint amountToWithdraw = _battleValueInWei.sub(fee);
        uint feeBalance = bwData.getFeeBalance();
        feeBalance = feeBalance.add(fee);
        bwData.setFeeBalance(feeBalance);
        subUserBattleValue(msgSender, _battleValueInWei, true);
        return amountToWithdraw;
    }

    function addUserBattleValue(address _userId, uint _amount) public isValidCaller {
        uint userBattleValue = bwData.getUserBattleValue(_userId);
        uint newBattleValue = userBattleValue.add(_amount);
        bwData.setUserBattleValue(_userId, newBattleValue);  
        emit UserBattleValueUpdated(_userId, newBattleValue, false);
    }
    
    function subUserBattleValue(address _userId, uint _amount, bool _isWithdraw) public isValidCaller {
        uint userBattleValue = bwData.getUserBattleValue(_userId);
        require(_amount <= userBattleValue);  
        uint newBattleValue = userBattleValue.sub(_amount);
        bwData.setUserBattleValue(_userId, newBattleValue);  
        emit UserBattleValueUpdated(_userId, newBattleValue, _isWithdraw);
    }

    function addGlobalBlockValueBalance(uint _amount) public isValidCaller {
         
        uint blockValueBalance = bwData.getBlockValueBalance();
        bwData.setBlockValueBalance(blockValueBalance.add(_amount));
    }

    function subGlobalBlockValueBalance(uint _amount) public isValidCaller {
         
        uint blockValueBalance = bwData.getBlockValueBalance();
        bwData.setBlockValueBalance(blockValueBalance.sub(_amount));
    }

     
    function transferTokens(address _tokenAddress, address _recipient) public isOwner {
        ERC20I token = ERC20I(_tokenAddress);
        require(token.transfer(_recipient, token.balanceOf(this)));
    }
}





contract BWData {
    address public owner;
    address private bwService;
    address private bw;
    address private bwMarket;

    uint private blockValueBalance = 0;
    uint private feeBalance = 0;
    uint private BASE_TILE_PRICE_WEI = 1 finney;  
    
    mapping (address => User) private users;  
    mapping (uint16 => Tile) private tiles;  
    
     
    struct User {
        uint creationTime;
        bool censored;
        uint battleValue;
    }

     
    struct Tile {
        address claimer;
        uint blockValue;
        uint creationTime;
        uint sellPrice;     
    }

    struct Boost {
        uint8 numAttackBoosts;
        uint8 numDefendBoosts;
        uint attackBoost;
        uint defendBoost;
    }

    constructor() public {
        owner = msg.sender;
    }

     
    function () payable public {
        revert();
    }

    function kill() public isOwner {
        selfdestruct(owner);
    }

    modifier isValidCaller {
        if (msg.sender != bwService && msg.sender != bw && msg.sender != bwMarket) {
            revert();
        }
        _;
    }
    
    modifier isOwner {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }
    
    function setBwServiceValidCaller(address _bwService) public isOwner {
        bwService = _bwService;
    }

    function setBwValidCaller(address _bw) public isOwner {
        bw = _bw;
    }

    function setBwMarketValidCaller(address _bwMarket) public isOwner {
        bwMarket = _bwMarket;
    }    
    
     
    
     
         
         
         
     
    
    function addUser(address _msgSender) public isValidCaller {
        User storage user = users[_msgSender];
        require(user.creationTime == 0);
        user.creationTime = block.timestamp;
    }

    function hasUser(address _user) view public isValidCaller returns (bool) {
        return users[_user].creationTime != 0;
    }
    

     

    function getTile(uint16 _tileId) view public isValidCaller returns (address, uint, uint, uint) {
        Tile storage currentTile = tiles[_tileId];
        return (currentTile.claimer, currentTile.blockValue, currentTile.creationTime, currentTile.sellPrice);
    }
    
    function getTileClaimerAndBlockValue(uint16 _tileId) view public isValidCaller returns (address, uint) {
        Tile storage currentTile = tiles[_tileId];
        return (currentTile.claimer, currentTile.blockValue);
    }
    
    function isNewTile(uint16 _tileId) view public isValidCaller returns (bool) {
        Tile storage currentTile = tiles[_tileId];
        return currentTile.creationTime == 0;
    }
    
    function storeClaim(uint16 _tileId, address _claimer, uint _blockValue) public isValidCaller {
        tiles[_tileId] = Tile(_claimer, _blockValue, block.timestamp, 0);
    }

    function updateTileBlockValue(uint16 _tileId, uint _blockValue) public isValidCaller {
        tiles[_tileId].blockValue = _blockValue;
    }

    function setClaimerForTile(uint16 _tileId, address _claimer) public isValidCaller {
        tiles[_tileId].claimer = _claimer;
    }

    function updateTileTimeStamp(uint16 _tileId) public isValidCaller {
        tiles[_tileId].creationTime = block.timestamp;
    }
    
    function getCurrentClaimerForTile(uint16 _tileId) view public isValidCaller returns (address) {
        Tile storage currentTile = tiles[_tileId];
        if (currentTile.creationTime == 0) {
            return 0;
        }
        return currentTile.claimer;
    }

    function getCurrentBlockValueAndSellPriceForTile(uint16 _tileId) view public isValidCaller returns (uint, uint) {
        Tile storage currentTile = tiles[_tileId];
        if (currentTile.creationTime == 0) {
            return (0, 0);
        }
        return (currentTile.blockValue, currentTile.sellPrice);
    }
    
    function getBlockValueBalance() view public isValidCaller returns (uint){
        return blockValueBalance;
    }

    function setBlockValueBalance(uint _blockValueBalance) public isValidCaller {
        blockValueBalance = _blockValueBalance;
    }

    function getFeeBalance() view public isValidCaller returns (uint) {
        return feeBalance;
    }

    function setFeeBalance(uint _feeBalance) public isValidCaller {
        feeBalance = _feeBalance;
    }
    
    function getUserBattleValue(address _userId) view public isValidCaller returns (uint) {
        return users[_userId].battleValue;
    }
    
    function setUserBattleValue(address _userId, uint _battleValue) public  isValidCaller {
        users[_userId].battleValue = _battleValue;
    }
    
    function verifyAmount(address _msgSender, uint _msgValue, uint _amount, bool _useBattleValue) view public isValidCaller {
        User storage user = users[_msgSender];
        require(user.creationTime != 0);

        if (_useBattleValue) {
            require(_msgValue == 0);
            require(user.battleValue >= _amount);
        } else {
            require(_amount == _msgValue);
        }
    }
    
    function addBoostFromTile(Tile _tile, address _attacker, address _defender, Boost memory _boost) pure private {
        if (_tile.claimer == _attacker) {
            require(_boost.attackBoost + _tile.blockValue >= _tile.blockValue);  
            _boost.attackBoost += _tile.blockValue;
            _boost.numAttackBoosts += 1;
        } else if (_tile.claimer == _defender) {
            require(_boost.defendBoost + _tile.blockValue >= _tile.blockValue);  
            _boost.defendBoost += _tile.blockValue;
            _boost.numDefendBoosts += 1;
        }
    }

    function calculateBattleBoost(uint16 _tileId, address _attacker, address _defender) view public isValidCaller returns (uint, uint) {
        uint8 x;
        uint8 y;

        (x, y) = BWUtility.fromTileId(_tileId);

        Boost memory boost = Boost(0, 0, 0, 0);
         
         
        if (y != 255) {
            if (x != 255) {
                addBoostFromTile(tiles[BWUtility.toTileId(x+1, y+1)], _attacker, _defender, boost);
            }
            
            addBoostFromTile(tiles[BWUtility.toTileId(x, y+1)], _attacker, _defender, boost);

            if (x != 0) {
                addBoostFromTile(tiles[BWUtility.toTileId(x-1, y+1)], _attacker, _defender, boost);
            }
        }

        if (x != 255) {
            addBoostFromTile(tiles[BWUtility.toTileId(x+1, y)], _attacker, _defender, boost);
        }

        if (x != 0) {
            addBoostFromTile(tiles[BWUtility.toTileId(x-1, y)], _attacker, _defender, boost);
        }

        if (y != 0) {
            if(x != 255) {
                addBoostFromTile(tiles[BWUtility.toTileId(x+1, y-1)], _attacker, _defender, boost);
            }

            addBoostFromTile(tiles[BWUtility.toTileId(x, y-1)], _attacker, _defender, boost);

            if(x != 0) {
                addBoostFromTile(tiles[BWUtility.toTileId(x-1, y-1)], _attacker, _defender, boost);
            }
        }
         
         
         
         
         
         
         
         
         
         
         
         
         
         
        boost.attackBoost = (boost.attackBoost / 10 * boost.numAttackBoosts);
        boost.defendBoost = (boost.defendBoost / 10 * boost.numDefendBoosts);

        return (boost.attackBoost, boost.defendBoost);
    }
    
    function censorUser(address _userAddress, bool _censored) public isValidCaller {
        User storage user = users[_userAddress];
        require(user.creationTime != 0);
        user.censored = _censored;
    }
    
    function deleteTile(uint16 _tileId) public isValidCaller {
        delete tiles[_tileId];
    }
    
    function setSellPrice(uint16 _tileId, uint _sellPrice) public isValidCaller {
        tiles[_tileId].sellPrice = _sellPrice;   
    }

    function deleteOffer(uint16 _tileId) public isValidCaller {
        tiles[_tileId].sellPrice = 0;   
    }
}



 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

 

interface LocalGameI {
    function getBountyBalance() view external returns (uint);
    function getTimeLeftToNextCollect(address _claimer, uint _latestClaimTime) view external returns (uint);
    function collectBounty(address _msgSender, uint _latestClaimTime, uint _amount) external returns (uint);
}

 
contract ERC721 {
     
     
     
     
     
     

     
     
     
     
     

     
     
     

     
     
     
     
     
    function balanceOf(address _owner) external view returns (uint256);

     
     
     
     
     
    function ownerOf(uint256 _tokenId) external view returns (address);

     
     
     
     
     
     
     
     
     
     
     
     
     

     
     
     
     
     
     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

     
     
     
     
     
     
     
     
     
     
     

     
     
     
     
     
     
     

     
     
     
     
     
     

     
     
     
     
     

     
     
     
     
     

     
     
     
     
     
     
     
}

contract BW { 
    using SafeMath for uint256;
    address public owner;
    BWService private bwService;
    BWData private bwData;
    bool public paused = false;
    uint private BV_TO_BP_FEE = 5;  
    mapping (uint16 => Prize[]) private prizes;  
    
    struct Prize {
        address token;  
        uint tokenId; 
        uint startTime;  
        uint hodlPeriod;  
    }

    event PrizeCreated(uint16 tileId,  address token, uint tokenId, uint creationTime, uint startTime, uint hodlPeriod);
    event PrizeRemoved(uint16 tileId, address token, uint tokenId, uint removeTime);
    event PrizeClaimed(address token, uint tokenId);

     
    function addPrize(uint16 _tileId, address _token, uint _tokenId, uint _startTime, uint _hodlPeriod) public isOwner {
         
        uint startTime = _startTime;
        if(startTime < block.timestamp) {
            startTime = block.timestamp;
        }
         
         
         
        prizes[_tileId].push(Prize(_token, _tokenId, startTime, _hodlPeriod));
        emit PrizeCreated(_tileId, _token, _tokenId, block.timestamp, startTime, _hodlPeriod);
    }

     
    function removePrize(uint16 _tileId, address _token, uint _tokenId) public isOwner {
        Prize[] storage prizeArr = prizes[_tileId];
        require(prizeArr.length > 0);

        for(uint idx = 0; idx < prizeArr.length; ++idx) {
            if(prizeArr[idx].tokenId == _tokenId && prizeArr[idx].token == _token) {
                delete prizeArr[idx];
                emit PrizeRemoved(_tileId, _token, _tokenId, block.timestamp);
            }
        }
    }

     
    function claimPrize(address _tokenAddress, uint16 _tileId) public isNotPaused isNotContractCaller {
        ERC721 token = ERC721(_tokenAddress);
        Prize[] storage prizeArr = prizes[_tileId];
        require(prizeArr.length > 0);
        address claimer;
        uint blockValue;
        uint lastClaimTime;
        uint sellPrice;
        (claimer, blockValue, lastClaimTime, sellPrice) = bwData.getTile(_tileId);
        require(lastClaimTime != 0 && claimer == msg.sender);

        for(uint idx = 0; idx < prizeArr.length; ++idx) {
            if(prizeArr[idx].startTime.add(prizeArr[idx].hodlPeriod) <= block.timestamp
                && lastClaimTime.add(prizeArr[idx].hodlPeriod) <= block.timestamp) {
                uint tokenId = prizeArr[idx].tokenId;
                address tokenOwner = token.ownerOf(tokenId);
                delete prizeArr[idx];
                token.safeTransferFrom(tokenOwner, msg.sender, tokenId);  
                emit PrizeClaimed(_tokenAddress, tokenId);
            }
        }
    }

    modifier isOwner {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }

     
    modifier isNotPaused {
        if (paused) {
            revert();
        }
        _;
    }

     
    modifier isNotContractCaller {
        require(msg.sender == tx.origin);
        _;
    }

     
    event UserCreated(address userAddress, bytes32 name, bytes imageUrl, bytes32 tag, bytes32 homeUrl, uint creationTime, address invitedBy);
    event UserCensored(address userAddress, bool isCensored);
    event TransferTileFromOwner(uint16 tileId, address seller, address buyer, uint acceptTime);  
    event UserUpdated(address userAddress, bytes32 name, bytes imageUrl, bytes32 tag, bytes32 homeUrl, uint updateTime);
    event TileRetreated(uint16 tileId, address owner, uint amount, uint newBlockValue, uint retreatTime);
    event BountyCollected(uint tile, address userAddress, uint amount, uint amountCollected, uint collectedTime, uint latestClaimTime);

     
    constructor(address _bwService, address _bwData) public {
        bwService = BWService(_bwService);
        bwData = BWData(_bwData);
        owner = msg.sender;
    }

     
    function () payable public isOwner {

    }

     
    function claimTilesForNewUser(bytes32 _name, bytes _imageUrl, bytes32 _tag, bytes32 _homeUrl, uint16[] _claimedTileIds, address _invitedBy) payable public isNotPaused isNotContractCaller {
        bwData.addUser(msg.sender);
        emit UserCreated(msg.sender, _name, _imageUrl, _tag, _homeUrl, block.timestamp, _invitedBy);
        bwService.storeInitialClaim(msg.sender, _claimedTileIds, msg.value, false);
    }

     
    function claimTilesForExistingUser(uint16[] _claimedTileIds, uint _claimAmount, bool _useBattleValue) payable public isNotPaused isNotContractCaller {
        bwService.verifyAmount(msg.sender, msg.value, _claimAmount, _useBattleValue);
        bwService.storeInitialClaim(msg.sender, _claimedTileIds, _claimAmount, _useBattleValue);
    }

     
    function updateUser(bytes32 _name, bytes _imageUrl, bytes32 _tag, bytes32 _homeUrl) public isNotPaused isNotContractCaller {
        require(bwData.hasUser(msg.sender));
         
        emit UserUpdated(msg.sender, _name, _imageUrl, _tag, _homeUrl, block.timestamp);
    }
    
     
     
     
     
    function fortifyClaims(uint16[] _claimedTileIds, uint _fortifyAmount, bool _useBattleValue) payable public isNotPaused isNotContractCaller {
        bwService.verifyAmount(msg.sender, msg.value, _fortifyAmount, _useBattleValue);
        bwService.fortifyClaims(msg.sender, _claimedTileIds, _fortifyAmount, _useBattleValue);
    }

     
    function attackTileForNewUser(uint16 _tileId, bytes32 _name, bytes _imageUrl, bytes32 _tag, bytes32 _homeUrl, address _invitedBy) payable public isNotPaused isNotContractCaller {
        bwData.addUser(msg.sender);
        emit UserCreated(msg.sender, _name, _imageUrl, _tag, _homeUrl, block.timestamp, _invitedBy);
        bwService.attackTile(msg.sender, _tileId, msg.value, false);
    }

     
    function attackTileForExistingUser(uint16 _tileId, uint _attackAmount, bool _useBattleValue) payable public isNotPaused isNotContractCaller {
        bwService.verifyAmount(msg.sender, msg.value, _attackAmount, _useBattleValue);
        bwService.attackTile(msg.sender, _tileId, _attackAmount, _useBattleValue);
    }
    
     
    function moveBlockValue(uint8 _xSource, uint8 _ySource, uint8 _xDest, uint8 _yDest, uint _moveAmount) public isNotPaused isNotContractCaller {
        require(_moveAmount > 0);
        bwService.moveBlockValue(msg.sender, _xSource, _ySource, _xDest, _yDest, _moveAmount);
    }

     
    function withdrawBattleValue(uint _battleValueInWei) public isNotContractCaller {
        require(_battleValueInWei > 0);
        uint amountToWithdraw = bwService.withdrawBattleValue(msg.sender, _battleValueInWei);
        msg.sender.transfer(amountToWithdraw);
    }

     
    function transferBlockValueToBattleValue(uint16 _tileId, uint _amount) public isNotContractCaller {
        require(_amount > 0);
        address claimer;
        uint blockValue;
        (claimer, blockValue) = bwData.getTileClaimerAndBlockValue(_tileId);
        require(claimer == msg.sender);
        uint newBlockValue = blockValue.sub(_amount);
         
        require(newBlockValue == 0 || newBlockValue >= 5 finney);
        if(newBlockValue == 0) {
            bwData.deleteTile(_tileId);
        } else {
            bwData.updateTileBlockValue(_tileId, newBlockValue);
            bwData.deleteOffer(_tileId);  
        }
        
        uint fee = _amount.mul(BV_TO_BP_FEE).div(100);
        uint userAmount = _amount.sub(fee);
        uint feeBalance = bwData.getFeeBalance();
        feeBalance = feeBalance.add(fee);
        bwData.setFeeBalance(feeBalance);

        bwService.addUserBattleValue(msg.sender, userAmount);
        bwService.subGlobalBlockValueBalance(_amount);
        emit TileRetreated(_tileId, msg.sender, _amount, newBlockValue, block.timestamp);
    }

     

    function getLocalBountyBalance(uint16 _tileId) view public isNotContractCaller returns (uint) {
        address localGameAddress = bwService.getLocalGame(_tileId);
        require(localGameAddress != 0);
        LocalGameI localGame = LocalGameI(localGameAddress);
        return localGame.getBountyBalance();
    }

    function getTimeLeftToNextLocalBountyCollect(uint16 _tileId) view public isNotContractCaller returns (uint) {
        address localGameAddress = bwService.getLocalGame(_tileId);
        require(localGameAddress != 0);
        LocalGameI localGame = LocalGameI(localGameAddress);
        address claimer;
        uint blockValue;
        uint latestClaimTime;
        uint sellPrice;
        (claimer, blockValue, latestClaimTime, sellPrice) = bwData.getTile(_tileId);
        return localGame.getTimeLeftToNextCollect(claimer, latestClaimTime);
    }

    function collectLocalBounty(uint16 _tileId, uint _amount) public isNotContractCaller {
        address localGameAddress = bwService.getLocalGame(_tileId);
        require(localGameAddress != 0);
        address claimer;
        uint blockValue;
        uint latestClaimTime;
        uint sellPrice;
        (claimer, blockValue, latestClaimTime, sellPrice) = bwData.getTile(_tileId);
        require(latestClaimTime != 0 && claimer == msg.sender);
        
        LocalGameI localGame = LocalGameI(localGameAddress);
        uint amountCollected = localGame.collectBounty(msg.sender, latestClaimTime, _amount);
        emit BountyCollected(_tileId, msg.sender, _amount, amountCollected, block.timestamp, latestClaimTime);
    }

     

     
     
    function createNewUser(bytes32 _name, bytes _imageUrl, bytes32 _tag, bytes32 _homeUrl, address _user) public isOwner {
        bwData.addUser(_user);
        emit UserCreated(_user, _name, _imageUrl, _tag, _homeUrl, block.timestamp, msg.sender);  
    }

     
     
     
    function censorUser(address _userAddress, bool _censored) public isOwner {
        bwData.censorUser(_userAddress, _censored);
        emit UserCensored(_userAddress, _censored);
    }

     
    function setPaused(bool _paused) public isOwner {
        paused = _paused;
    }

    function kill() public isOwner {
        selfdestruct(owner);
    }
    
    function withdrawFee() public isOwner {
        uint balance = address(this).balance;
        uint amountToWithdraw = bwData.getFeeBalance();

        if (balance < amountToWithdraw) {  
            amountToWithdraw = balance;
        }
        bwData.setFeeBalance(0);

        owner.transfer(amountToWithdraw);
    }

    function getFee() view public isOwner returns (uint) {
        return bwData.getFeeBalance();
    }

    function setBvToBpFee(uint _feePercentage) public isOwner {
        BV_TO_BP_FEE = _feePercentage;
    }

    function depositBattleValue(address _user) payable public isOwner {
        require(msg.value % 1 finney == 0);  
        bwService.addUserBattleValue(_user, msg.value);
    }

     
    function transferTileFromOwner(uint16[] _tileIds, address _newOwner) public isOwner {
        for(uint i = 0; i < _tileIds.length; ++i) {
            uint16 tileId = _tileIds[i];
            address claimer = bwData.getCurrentClaimerForTile(tileId);
            require(claimer == owner);
            bwData.setClaimerForTile(tileId, _newOwner);
            
            emit TransferTileFromOwner(tileId, _newOwner, msg.sender, block.timestamp);
        }
    }

     
    function transferTokens(address _tokenAddress, address _recipient) public isOwner {
        ERC20I token = ERC20I(_tokenAddress);
        require(token.transfer(_recipient, token.balanceOf(this)));
    }
}