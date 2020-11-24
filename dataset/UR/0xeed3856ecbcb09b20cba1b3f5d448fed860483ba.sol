 

pragma solidity ^0.4.19;

 
contract ERCInterface {
    function transferFrom(address _from, address _to, uint256 _value) public;
    function balanceOf(address who) constant public returns (uint256);
    function allowance(address owner, address spender) constant public returns (uint256);
    function transfer(address to, uint256 value) public returns(bool);
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


     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


contract Ownable {
    
    address public owner;
    
    event OwnershipTransferred(address indexed from, address indexed to);
    
    
     
    function Ownable() public {
        owner = msg.sender;
    }


     
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        require(
            _newOwner != address(0)
            && _newOwner != owner 
        );
        OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}



contract DappleAirdrops is Ownable {
    
    using SafeMath for uint256;
    
    mapping (address => uint256) public bonusDropsOf;
    mapping (address => uint256) public ethBalanceOf;
    mapping (address => bool) public tokenIsBanned;
    mapping (address => uint256) public trialDrops;
        
    uint256 public rate;
    uint256 public dropUnitPrice;
    uint256 public bonus;
    uint256 public maxDropsPerTx;
    uint256 public maxTrialDrops;
    string public constant website = "www.dappleairdrops.com";
    
    event BonusCreditGranted(address indexed to, uint256 credit);
    event BonusCreditRevoked(address indexed from, uint256 credit);
    event CreditPurchased(address indexed by, uint256 etherValue, uint256 credit);
    event AirdropInvoked(address indexed by, uint256 creditConsumed);
    event BonustChanged(uint256 from, uint256 to);
    event TokenBanned(address indexed tokenAddress);
    event TokenUnbanned(address indexed tokenAddress);
    event EthWithdrawn(address indexed by, uint256 totalWei);
    event RateChanged(uint256 from, uint256 to);
    event MaxDropsChanged(uint256 from, uint256 to);
    event RefundIssued(address indexed to, uint256 totalWei);
    event ERC20TokensWithdrawn(address token, address sentTo, uint256 value);

    
     
    function DappleAirdrops() public {
        rate = 10000;
        dropUnitPrice = 1e14; 
        bonus = 20;
        maxDropsPerTx = 100;
        maxTrialDrops = 100;
    }
    
    
     
    function tokenHasFreeTrial(address _addressOfToken) public view returns(bool) {
        return trialDrops[_addressOfToken] < maxTrialDrops;
    }
    
    
     
    function getRemainingTrialDrops(address _addressOfToken) public view returns(uint256) {
        if(tokenHasFreeTrial(_addressOfToken)) {
            return maxTrialDrops.sub(trialDrops[_addressOfToken]);
        } 
        return 0;
    }
    
    
     
    function setRate(uint256 _newRate) public onlyOwner returns(bool) {
        require(
            _newRate != rate 
            && _newRate > 0
        );
        RateChanged(rate, _newRate);
        rate = _newRate;
        uint256 eth = 1 ether;
        dropUnitPrice = eth.div(rate);
        return true;
    }
    
    
    function getRate() public view returns(uint256) {
        return rate;
    }

    
     
    function getMaxDropsPerTx() public view returns(uint256) {
        return maxDropsPerTx;
    }
    
    
     
    function setMaxDrops(uint256 _maxDrops) public onlyOwner returns(bool) {
        require(_maxDrops >= 100);
        MaxDropsChanged(maxDropsPerTx, _maxDrops);
        maxDropsPerTx = _maxDrops;
        return true;
    }
    
     
    function setBonus(uint256 _newBonus) public onlyOwner returns(bool) {
        require(bonus != _newBonus);
        BonustChanged(bonus, _newBonus);
        bonus = _newBonus;
    }
    
    
     
    function grantBonusDrops(address _addr, uint256 _bonusDrops) public onlyOwner returns(bool) {
        require(
            _addr != address(0) 
            && _bonusDrops > 0
        );
        bonusDropsOf[_addr] = bonusDropsOf[_addr].add(_bonusDrops);
        BonusCreditGranted(_addr, _bonusDrops);
        return true;
    }
    
    
     
    function revokeBonusCreditOf(address _addr, uint256 _bonusDrops) public onlyOwner returns(bool) {
        require(
            _addr != address(0) 
            && bonusDropsOf[_addr] >= _bonusDrops
        );
        bonusDropsOf[_addr] = bonusDropsOf[_addr].sub(_bonusDrops);
        BonusCreditRevoked(_addr, _bonusDrops);
        return true;
    }
    
    
     
    function getDropsOf(address _addr) public view returns(uint256) {
        return (ethBalanceOf[_addr].mul(rate)).div(10 ** 18);
    }
    
    
     
    function getBonusDropsOf(address _addr) public view returns(uint256) {
        return bonusDropsOf[_addr];
    }
    
    
     
    function getTotalDropsOf(address _addr) public view returns(uint256) {
        return getDropsOf(_addr).add(getBonusDropsOf(_addr));
    }
    
    
     
    function getEthBalanceOf(address _addr) public view returns(uint256) {
        return ethBalanceOf[_addr];
    }

    
     
    function banToken(address _tokenAddr) public onlyOwner returns(bool) {
        require(!tokenIsBanned[_tokenAddr]);
        tokenIsBanned[_tokenAddr] = true;
        TokenBanned(_tokenAddr);
        return true;
    }
    
    
     
    function unbanToken(address _tokenAddr) public onlyOwner returns(bool) {
        require(tokenIsBanned[_tokenAddr]);
        tokenIsBanned[_tokenAddr] = false;
        TokenUnbanned(_tokenAddr);
        return true;
    }
    
    
     
    function getTokenAllowance(address _addr, address _addressOfToken) public view returns(uint256) {
        ERCInterface token = ERCInterface(_addressOfToken);
        return token.allowance(_addr, address(this));
    }
    
    
     
    function() public payable {
        ethBalanceOf[msg.sender] = ethBalanceOf[msg.sender].add(msg.value);
        CreditPurchased(msg.sender, msg.value, msg.value.mul(rate));
    }

    
     
    function withdrawEth(uint256 _eth) public returns(bool) {
        require(
            ethBalanceOf[msg.sender] >= _eth
            && _eth > 0 
        );
        uint256 toTransfer = _eth;
        ethBalanceOf[msg.sender] = ethBalanceOf[msg.sender].sub(_eth);
        msg.sender.transfer(toTransfer);
        EthWithdrawn(msg.sender, toTransfer);
    }
    
    
     
    function issueRefunds(address[] _addrs) public onlyOwner returns(bool) {
        require(_addrs.length <= maxDropsPerTx);
        for(uint i = 0; i < _addrs.length; i++) {
            if(_addrs[i] != address(0) && ethBalanceOf[_addrs[i]] > 0) {
                uint256 toRefund = ethBalanceOf[_addrs[i]];
                ethBalanceOf[_addrs[i]] = 0;
                _addrs[i].transfer(toRefund);
                RefundIssued(_addrs[i], toRefund);
            }
        }
    }
    
    
     
    function singleValueAirdrop(address _addressOfToken,  address[] _recipients, uint256 _value) public returns(bool) {
        ERCInterface token = ERCInterface(_addressOfToken);
        require(
            _recipients.length <= maxDropsPerTx 
            && (
                getTotalDropsOf(msg.sender)>= _recipients.length 
                || tokenHasFreeTrial(_addressOfToken) 
            )
            && !tokenIsBanned[_addressOfToken]
        );
        for(uint i = 0; i < _recipients.length; i++) {
            if(_recipients[i] != address(0)) {
                token.transferFrom(msg.sender, _recipients[i], _value);
            }
        }
        if(tokenHasFreeTrial(_addressOfToken)) {
            trialDrops[_addressOfToken] = trialDrops[_addressOfToken].add(_recipients.length);
        } else {
            updateMsgSenderBonusDrops(_recipients.length);
        }
        AirdropInvoked(msg.sender, _recipients.length);
        return true;
    }
    
    
         
    function multiValueAirdrop(address _addressOfToken,  address[] _recipients, uint256[] _values) public returns(bool) {
        ERCInterface token = ERCInterface(_addressOfToken);
        require(
            _recipients.length <= maxDropsPerTx 
            && _recipients.length == _values.length 
            && (
                getTotalDropsOf(msg.sender) >= _recipients.length
                || tokenHasFreeTrial(_addressOfToken)
            )
            && !tokenIsBanned[_addressOfToken]
        );
        for(uint i = 0; i < _recipients.length; i++) {
            if(_recipients[i] != address(0) && _values[i] > 0) {
                token.transferFrom(msg.sender, _recipients[i], _values[i]);
            }
        }
        if(tokenHasFreeTrial(_addressOfToken)) {
            trialDrops[_addressOfToken] = trialDrops[_addressOfToken].add(_recipients.length);
        } else {
            updateMsgSenderBonusDrops(_recipients.length);
        }
        AirdropInvoked(msg.sender, _recipients.length);
        return true;
    }
    
    
     
    function updateMsgSenderBonusDrops(uint256 _drops) internal {
        if(_drops <= getDropsOf(msg.sender)) {
            bonusDropsOf[msg.sender] = bonusDropsOf[msg.sender].add(_drops.mul(bonus).div(100));
            ethBalanceOf[msg.sender] = ethBalanceOf[msg.sender].sub(_drops.mul(dropUnitPrice));
            owner.transfer(_drops.mul(dropUnitPrice));
        } else {
            uint256 remainder = _drops.sub(getDropsOf(msg.sender));
            if(ethBalanceOf[msg.sender] > 0) {
                bonusDropsOf[msg.sender] = bonusDropsOf[msg.sender].add(getDropsOf(msg.sender).mul(bonus).div(100));
                owner.transfer(ethBalanceOf[msg.sender]);
                ethBalanceOf[msg.sender] = 0;
            }
            bonusDropsOf[msg.sender] = bonusDropsOf[msg.sender].sub(remainder);
        }
    }
    

       
    function withdrawERC20Tokens(address _addressOfToken,  address _recipient, uint256 _value) public onlyOwner returns(bool){
        require(
            _addressOfToken != address(0)
            && _recipient != address(0)
            && _value > 0
        );
        ERCInterface token = ERCInterface(_addressOfToken);
        token.transfer(_recipient, _value);
        ERC20TokensWithdrawn(_addressOfToken, _recipient, _value);
        return true;
    }
}