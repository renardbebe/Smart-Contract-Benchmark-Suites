 

pragma solidity ^0.4.25;

 

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);  
    uint256 c = a / b;
     

    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

 
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

   
  function owner() public view returns(address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

   
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

   
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract ERC721 {
    function implementsERC721() public pure returns (bool);
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) public view returns (address owner);
    function transfer(address _to, uint256 _tokenId) public returns (bool);
    
    event Transfer(
        address indexed from, 
        address indexed to, 
        uint256 indexed tokenId
    );
}

contract KillFish is Ownable, ERC721 {
    
    using SafeMath for uint256;
    using SafeMath for uint64;
    
     
    
    struct Fish {  
        uint64 genes;        
        string nickname;     
        uint64 birthTime;    
        uint64 feedTime;     
        uint64 huntTime;     
        uint256 share;       
        uint256 feedValue;   
        uint256 eatenValue;  
    }
    
     
    
    Fish[] fishes;
    
    mapping (uint256 => address) private _tokenOwner;
    
    mapping (address => uint256) private _ownedTokensCount;
    
    uint256 private _totalSupply;
    
    uint256 public totalShares;
    
    uint256 public balanceFishes;
    uint256 public balanceOwner;
    uint256 public balanceMarketing;
    
    uint256 public maxGasPrice;
    
     
    
    string constant public name = "KillFish.io";
    string constant public symbol = "FISH";
    
    uint256 constant public minPayment = 10000 szabo;    
    uint8 constant public percentFeeFishesInput = 5;
    uint8 constant public percentFeeFishesOutput = 5;
    uint8 constant public percentFeeFishesBite = 20;
    
    uint8 constant public percentFeeMarketingInput = 5;
    uint8 constant public percentFeeAdminOutput = 5;
    uint8 constant public percentFeeAdminBite = 10;
    
    uint8 constant public percentFeed = 5;
    
    uint64 constant public pausePrey = 7 days;
    uint64 constant public pauseHunter = 2 days;
    
     
    
    event UpdateMaxGasPrice(
        uint256 maxGasPrice
    );
    event WithdrawalMarketing(
        address indexed to, 
        uint256 value
    );
    event WithdrawalOwner(
        address indexed to, 
        uint256 value
    );
    
    function updateMaxGasPrice(uint256 _newMaxGasPrice) public onlyOwner {
        require(_newMaxGasPrice >= 10000000000 wei);  
        
        maxGasPrice=_newMaxGasPrice;
        
        emit UpdateMaxGasPrice(maxGasPrice);
    }
    
    function withdrawalMarketing(address _to, uint256 _value) public onlyOwner {
        balanceMarketing=balanceMarketing.sub(_value);
        emit WithdrawalMarketing(_to, _value);
        
        _to.transfer(_value);
    }
    
    function withdrawalOwner(address _to, uint256 _value) public onlyOwner {
        balanceOwner=balanceOwner.sub(_value);
        emit WithdrawalOwner(_to, _value);
        
        _to.transfer(_value);
    }
    
    constructor() public {
        
        updateMaxGasPrice(25000000000 wei);  
        
    }
    
     
    
    modifier onlyOwnerOf(uint256 _tokenId) {
        require(msg.sender == _tokenOwner[_tokenId], "not token owner");
        _;
    }
    
    function implementsERC721() public pure returns (bool) {
        return true;
    }
    
    function totalSupply() public view returns (uint256 total) {
        return _totalSupply;
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return _ownedTokensCount[_owner];
    }
    
    function ownerOf(uint256 _tokenId) public view returns (address owner) {
        return _tokenOwner[_tokenId];
    }
    
    function _transfer(address _from, address _to, uint256 _tokenId) private returns (bool) {
        _ownedTokensCount[_to] = _ownedTokensCount[_to].add(1);
        _ownedTokensCount[_from] = _ownedTokensCount[_from].sub(1);
        _tokenOwner[_tokenId] = _to;
        emit Transfer(_from, _to, _tokenId);
        return true;
    }
    
    function transfer(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) returns (bool)  {
        return _transfer(msg.sender, _to, _tokenId);
    }
    
     
    
    function () public payable {
        revert();
    }

     
    
    event CreateFish(
        uint256 indexed tokenId,
        uint64 genes,
        string nickname,
        uint64 birthTime,
        uint256 share,
        uint256 feedValue,
        uint256 eatenValue
    );
    event FeedFish(
        uint256 indexed tokenId,
        uint256 share,
        uint256 feedValue,
        uint256 eatenValue
    );
    event DestroyFish(
        uint256 indexed tokenId,
        uint256 share,
        uint256 withdrawal
    );    
    event BiteFish(
        uint256 indexed tokenId,
        uint256 indexed preyId,
        uint256 hunterShare,
        uint256 hunterFeedValue,
        uint256 preyShare,
        uint256 preyFeedValue
    );
    event UpdateNickname(
        uint256 indexed tokenId,
        string nickname
    );    
    
    modifier checkMaxGasPrice() {
        require(tx.gasprice<=maxGasPrice, "gas price > maxGasPrice");
        _;
    }
    
    modifier checkMinPayment() {
        require(msg.value>=minPayment, "msg.value < minPayment");
        _;
    }
    
    function createFish(string _nickname) public payable checkMinPayment checkMaxGasPrice returns(uint256) {
        
        uint256 feeMarketing=msg.value.mul(percentFeeMarketingInput).div(100);
        uint256 feeFishes=msg.value.mul(percentFeeFishesInput).div(100);
        uint256 value=msg.value.sub(feeMarketing).sub(feeFishes);
        
        balanceFishes=balanceFishes.add(value).add(feeFishes);
        balanceMarketing=balanceMarketing.add(feeMarketing);
        
        uint256 share=_newShare(value);
        
        totalShares=totalShares.add(share);
        
        Fish memory newFish=Fish({
            genes: _newGenes(),
            nickname: _nickname,
            birthTime: uint64(now),
            feedTime: uint64(now),
            huntTime: uint64(now), 
            share: share,
            feedValue: _newFeedValue(share),
            eatenValue: value
        });
        uint256 newTokenId = fishes.push(newFish) - 1;
        
        _totalSupply=_totalSupply.add(1);
        _ownedTokensCount[msg.sender]=_ownedTokensCount[msg.sender].add(1);
        _tokenOwner[newTokenId]=msg.sender;
        
        emit CreateFish(newTokenId, fishes[newTokenId].genes, fishes[newTokenId].nickname, fishes[newTokenId].birthTime, fishes[newTokenId].share, fishes[newTokenId].feedValue, value);
        emit Transfer(address(0), msg.sender, newTokenId);
        
        return newTokenId;
    }
    
    function feedFish(uint256 _tokenId) public payable checkMinPayment checkMaxGasPrice returns(bool) {
        require(statusLive(_tokenId), "fish dead");
        
        uint256 feeMarketing=msg.value.mul(percentFeeMarketingInput).div(100);
        uint256 feeFishes=msg.value.mul(percentFeeFishesInput).div(100);
        uint256 value=msg.value.sub(feeMarketing).sub(feeFishes);
        
        balanceFishes=balanceFishes.add(value).add(feeFishes);
        balanceMarketing=balanceMarketing.add(feeMarketing);
        
        uint256 share=_newShare(value);
        
        totalShares=totalShares.add(share);
        fishes[_tokenId].share=fishes[_tokenId].share.add(share);
        fishes[_tokenId].eatenValue=fishes[_tokenId].eatenValue.add(value);
        
        if (value<fishes[_tokenId].feedValue) {
            fishes[_tokenId].feedValue=fishes[_tokenId].feedValue.sub(value);
        } else {
            fishes[_tokenId].feedValue=_newFeedValue(fishes[_tokenId].share);
            fishes[_tokenId].feedTime=uint64(now);
            fishes[_tokenId].huntTime=uint64(now);
        }
        
        emit FeedFish(_tokenId, share, fishes[_tokenId].feedValue, value);
        
        return true;
    }

    function destroyFish(uint256 _tokenId) public onlyOwnerOf(_tokenId) checkMaxGasPrice returns(bool) {
        
        uint256 share=fishes[_tokenId].share;
        uint256 withdrawal=shareToValue(share);
        uint256 feeFishes=withdrawal.mul(percentFeeFishesOutput).div(100);
        uint256 feeAdmin=withdrawal.mul(percentFeeAdminOutput).div(100);
        
        withdrawal=withdrawal.sub(feeFishes).sub(feeAdmin);
        
        totalShares=totalShares.sub(share);
        fishes[_tokenId].share=0;
        fishes[_tokenId].feedValue=0;
        fishes[_tokenId].nickname="";
        fishes[_tokenId].feedTime=uint64(now);
        
        _transfer(msg.sender, address(0), _tokenId);
        
        balanceOwner=balanceOwner.add(feeAdmin);
        balanceFishes=balanceFishes.sub(withdrawal).sub(feeAdmin);
        
        emit DestroyFish(_tokenId, share, withdrawal);
        
        msg.sender.transfer(withdrawal);
        
        return true;   
    }
    
    function biteFish(uint256 _tokenId, uint256 _preyId) public onlyOwnerOf(_tokenId) checkMaxGasPrice returns(bool) {
        require(statusLive(_preyId), "prey dead");
        require(statusPrey(_preyId), "not prey");
        require(statusHunter(_tokenId), "not hunter");
        require(fishes[_preyId].share<fishes[_tokenId].share, "too much prey");
        
        uint256 sharePrey;
        uint256 shareHunter;
        uint256 shareFishes;
        uint256 shareAdmin;
        uint256 value;
        
        if (shareToValue(fishes[_preyId].share)<minPayment.mul(2)) {
            sharePrey=fishes[_preyId].share;
            
            _transfer(ownerOf(_preyId), address(0), _preyId);
            fishes[_preyId].nickname="";
        } else {
            sharePrey=fishes[_preyId].share.mul(percentFeed).div(100);
            
            if (shareToValue(sharePrey)<minPayment) {
                sharePrey=valueToShare(minPayment);
            }

        }
        
        shareFishes=sharePrey.mul(percentFeeFishesBite).div(100);
        shareAdmin=sharePrey.mul(percentFeeAdminBite).div(100);
        shareHunter=sharePrey.sub(shareFishes).sub(shareAdmin);
        
        fishes[_preyId].share=fishes[_preyId].share.sub(sharePrey);
        fishes[_tokenId].share=fishes[_tokenId].share.add(shareHunter);
        
        fishes[_preyId].feedValue=_newFeedValue(fishes[_preyId].share);
        fishes[_preyId].feedTime=uint64(now);
        
        fishes[_tokenId].huntTime=uint64(now);
        
        value=shareToValue(shareHunter);
        
        if (value<fishes[_tokenId].feedValue) {
            fishes[_tokenId].feedValue=fishes[_tokenId].feedValue.sub(value);
        } else {
            fishes[_tokenId].feedValue=_newFeedValue(fishes[_tokenId].share);
            fishes[_tokenId].feedTime=uint64(now);
        }
        
        value=shareToValue(shareAdmin);
        
        totalShares=totalShares.sub(shareFishes).sub(shareAdmin);
        
        balanceOwner=balanceOwner.add(value);
        balanceFishes=balanceFishes.sub(value);
        
        emit BiteFish(_tokenId, _preyId, shareHunter, fishes[_tokenId].feedValue, sharePrey, fishes[_preyId].feedValue);
        
        return true;        
    }
    
    function updateNickname(uint256 _tokenId, string _nickname) public onlyOwnerOf(_tokenId) returns(bool) {
        
        fishes[_tokenId].nickname=_nickname;
        
        emit UpdateNickname(_tokenId, _nickname);
        
        return true;
    }
    
     
    
    function getFish(uint256 _tokenId) public view
        returns (
        uint64 genes,
        string nickname,
        uint64 birthTime,
        uint64 feedTime,
        uint64 huntTime,
        uint256 share,
        uint256 feedValue,
        uint256 eatenValue
    ) {
        Fish memory fish=fishes[_tokenId];
        
        genes=fish.genes;
        nickname=fish.nickname;
        birthTime=fish.birthTime;
        feedTime=fish.feedTime;
        huntTime=fish.huntTime;
        share=fish.share; 
        feedValue=fish.feedValue; 
        eatenValue=fish.eatenValue; 
    }

    function statusLive(uint256 _tokenId) public view returns(bool) {
        if (fishes[_tokenId].share==0) {return false;}
        return true;
    }
    
    function statusPrey(uint256 _tokenId) public view returns(bool) {
        if (now<=fishes[_tokenId].feedTime.add(pausePrey)) {return false;}
        return true;
    }
    
    function statusHunter(uint256 _tokenId) public view returns(bool) {
        if (now<=fishes[_tokenId].huntTime.add(pauseHunter)) {return false;}
        return true;
    }
    
    function shareToValue(uint256 _share) public view returns(uint256) {
        if (totalShares == 0) {return 0;}
        return _share.mul(balanceFishes).div(totalShares);
    }
    
    function valueToShare(uint256 _value) public view returns(uint256) {
        if (balanceFishes == 0) {return 0;}
        return _value.mul(totalShares).div(balanceFishes);
    }
    
    function _newShare(uint256 _value) private view returns(uint256) {
        if (totalShares == 0) {return _value;}
        return _value.mul(totalShares).div(balanceFishes.sub(_value));
    }
    
    function _newFeedValue(uint256 _share) private view returns(uint256) {
        uint256 _value=shareToValue(_share);
        return _value.mul(percentFeed).div(100);
    }
    
    function _newGenes() private view returns(uint64) {
        return uint64(uint256(keccak256(abi.encodePacked(now, totalShares, balanceFishes)))%(10**11));
    }
    
}