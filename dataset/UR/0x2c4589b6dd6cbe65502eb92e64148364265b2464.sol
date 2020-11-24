 

pragma solidity ^0.4.21;

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
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


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}


 
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

   
  function reclaimToken(ERC20Basic token) external onlyOwner {
    uint256 balance = token.balanceOf(this);
    token.safeTransfer(owner, balance);
  }

}


 
contract HasNoContracts is Ownable {

   
  function reclaimContract(address contractAddr) external onlyOwner {
    Ownable contractInst = Ownable(contractAddr);
    contractInst.transferOwnership(owner);
  }
}


 
contract HasNoTokens is CanReclaimToken {

  
  function tokenFallback(address from_, uint256 value_, bytes data_) external {
    from_;
    value_;
    data_;
    revert();
  }

}


 
contract HasNoEther is Ownable {

   
  function HasNoEther() public payable {
    require(msg.value == 0);
  }

   
  function() external {
  }

   
  function reclaimEther() external onlyOwner {
    assert(owner.send(this.balance));
  }
}


 
contract NoOwner is HasNoEther, HasNoTokens, HasNoContracts {
}


 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}


 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


 
contract BetexToken is StandardToken, NoOwner {

    string public constant name = "Betex Token";  
    string public constant symbol = "BETEX";  
    uint8 public constant decimals = 18;  

     
    uint256 public firstUnlockTime;

     
    uint256 public secondUnlockTime; 

     
    mapping (address => bool) public blockedTillSecondUnlock;

     
    address[] public holders;

     
    mapping (address => uint256) public holderNumber;

     
    address public icoAddress;

     
    uint256 public constant TOTAL_SUPPLY = 10000000 * (10 ** uint256(decimals));
    uint256 public constant SALE_SUPPLY = 5000000 * (10 ** uint256(decimals));

     
    uint256 public constant BOUNTY_SUPPLY = 200000 * (10 ** uint256(decimals));
    uint256 public constant RESERVE_SUPPLY = 800000 * (10 ** uint256(decimals));
    uint256 public constant BROKER_RESERVE_SUPPLY = 1000000 * (10 ** uint256(decimals));
    uint256 public constant TEAM_SUPPLY = 3000000 * (10 ** uint256(decimals));

     
    address public constant BOUNTY_ADDRESS = 0x48c15e5A9343E3220cdD8127620AE286A204448a;
    address public constant RESERVE_ADDRESS = 0xC8fE659AaeF73b6e41DEe427c989150e3eDAf57D;
    address public constant BROKER_RESERVE_ADDRESS = 0x8697d46171aBCaD2dC5A4061b8C35f909a402417;
    address public constant TEAM_ADDRESS = 0x1761988F02C75E7c3432fa31d179cad6C5843F24;

     
    uint256 public constant MIN_HOLDER_TOKENS = 10 ** uint256(decimals - 1);
    
     
    function BetexToken
    (
        uint256 _firstUnlockTime, 
        uint256 _secondUnlockTime
    )
        public 
    {        
        require(_secondUnlockTime > firstUnlockTime);

        firstUnlockTime = _firstUnlockTime;
        secondUnlockTime = _secondUnlockTime;

         
        balances[BOUNTY_ADDRESS] = BOUNTY_SUPPLY;
        holders.push(BOUNTY_ADDRESS);
        emit Transfer(0x0, BOUNTY_ADDRESS, BOUNTY_SUPPLY);

         
        balances[RESERVE_ADDRESS] = RESERVE_SUPPLY;
        holders.push(RESERVE_ADDRESS);
        emit Transfer(0x0, RESERVE_ADDRESS, RESERVE_SUPPLY);

         
        balances[BROKER_RESERVE_ADDRESS] = BROKER_RESERVE_SUPPLY;
        holders.push(BROKER_RESERVE_ADDRESS);
        emit Transfer(0x0, BROKER_RESERVE_ADDRESS, BROKER_RESERVE_SUPPLY);

         
        balances[TEAM_ADDRESS] = TEAM_SUPPLY;
        holders.push(TEAM_ADDRESS);
        emit Transfer(0x0, TEAM_ADDRESS, TEAM_SUPPLY);

        totalSupply_ = TOTAL_SUPPLY.sub(SALE_SUPPLY);
    }

     
    function setICO(address _icoAddress) public onlyOwner {
        require(_icoAddress != address(0));
        require(icoAddress == address(0));
        require(totalSupply_ == TOTAL_SUPPLY.sub(SALE_SUPPLY));
        
         
        balances[_icoAddress] = SALE_SUPPLY;
        emit Transfer(0x0, _icoAddress, SALE_SUPPLY);

        icoAddress = _icoAddress;
        totalSupply_ = TOTAL_SUPPLY;
    }
    
     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(transferAllowed(msg.sender));
        enforceSecondLock(msg.sender, _to);
        preserveHolders(msg.sender, _to, _value);
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(transferAllowed(msg.sender));
        enforceSecondLock(msg.sender, _to);
        preserveHolders(_from, _to, _value);
        return super.transferFrom(_from, _to, _value);
    }

     
    function getHoldersCount() public view returns (uint256) {
        return holders.length;
    }

     
    function enforceSecondLock(address _from, address _to) internal {
        if (now < secondUnlockTime) {  
            if (_from == TEAM_ADDRESS || _from == BROKER_RESERVE_ADDRESS) {
                require(balances[_to] == uint256(0) || blockedTillSecondUnlock[_to]);
                blockedTillSecondUnlock[_to] = true;
            }
        }
    }

     
    function preserveHolders(address _from, address _to, uint256 _value) internal {
        if (balances[_from].sub(_value) < MIN_HOLDER_TOKENS) 
            removeHolder(_from);
        if (balances[_to].add(_value) >= MIN_HOLDER_TOKENS) 
            addHolder(_to);   
    }

     
    function removeHolder(address _holder) internal {
        uint256 _number = holderNumber[_holder];

        if (_number == 0 || holders.length == 0 || _number > holders.length)
            return;

        uint256 _index = _number.sub(1);
        uint256 _lastIndex = holders.length.sub(1);
        address _lastHolder = holders[_lastIndex];

        if (_index != _lastIndex) {
            holders[_index] = _lastHolder;
            holderNumber[_lastHolder] = _number;
        }

        holderNumber[_holder] = 0;
        holders.length = _lastIndex;
    } 

     
    function addHolder(address _holder) internal {
        if (holderNumber[_holder] == 0) {
            holders.push(_holder);
            holderNumber[_holder] = holders.length;
        }
    }

     
    function transferAllowed(address _sender) internal view returns(bool) {
        if (now > secondUnlockTime || _sender == icoAddress)  
            return true;
        if (now < firstUnlockTime)  
            return false;
        if (blockedTillSecondUnlock[_sender])
            return false;
        return true;
    }

}


 
contract BetexStorage is Ownable {

     
    uint256 public constant VOLUME_BONUS_CONDITION = 50 ether;

     
    uint256 public constant VOLUME_EXTRA_BONUS_CONDITION = 100 ether;

     
    uint256 public constant FIRST_VOLUME_EXTRA_BONUS = 20;

     
    uint256 public constant SECOND_VOLUME_EXTRA_BONUS = 10;

     
    uint256 public constant FIRST_VOLUME_BONUS = 10;

     
    uint256 public constant SECOND_VOLUME_BONUS = 5;

     
    struct Order {
        address beneficiary;
        uint256 funds;
        uint256 bonus;
        uint256 rate;
    }

     
    mapping (bytes32 => Order) public orders;

     
    mapping (bytes32 => bool) public unsoldAllocationOrders;

     
    mapping (address => bool) public whitelist;

     
    mapping (address => bool) public funded;

     
    address[] public funders;
    
     
    address[] public preICOFunders;

     
    mapping (address => uint256) public preICOBalances;

     
    bool public preICODataInitialized;


       
    function BetexStorage() public {

         
        preICOFunders.push(0x233Fd2B3d7a0924Fe1Bb0dd7FA168eEF8C522E65);
        preICOBalances[0x233Fd2B3d7a0924Fe1Bb0dd7FA168eEF8C522E65] = 15000000000000000000000;
        preICOFunders.push(0x2712ba56cB3Cf8783693c8a1796F70ABa57132b1);
        preICOBalances[0x2712ba56cB3Cf8783693c8a1796F70ABa57132b1] = 15000000000000000000000;
        preICOFunders.push(0x6f3DDfb726eA637e125C4fbf6694B940711478f4);
        preICOBalances[0x6f3DDfb726eA637e125C4fbf6694B940711478f4] = 15000000000000000000000;
        preICOFunders.push(0xAf7Ff6f381684707001d517Bf83C4a3538f9C82a);
        preICOBalances[0xAf7Ff6f381684707001d517Bf83C4a3538f9C82a] = 22548265874120000000000;
        preICOFunders.push(0x51219a9330c196b8bd7fA0737C8e0db53c1ad628);
        preICOBalances[0x51219a9330c196b8bd7fA0737C8e0db53c1ad628] = 32145215844400000000000;
        preICOFunders.push(0xA2D42D689769f7BA32712f27B09606fFD8F3b699);
        preICOBalances[0xA2D42D689769f7BA32712f27B09606fFD8F3b699] = 15000000000000000000000;
        preICOFunders.push(0xB7C9D3AAbF44296232538B8b184F274B57003994);
        preICOBalances[0xB7C9D3AAbF44296232538B8b184F274B57003994] = 20000000000000000000000;
        preICOFunders.push(0x58667a170F53b809CA9143c1CeEa00D2Df866577);
        preICOBalances[0x58667a170F53b809CA9143c1CeEa00D2Df866577] = 184526257787000000000000;
        preICOFunders.push(0x0D4b2A1a47b1059d622C033c2a58F2F651010553);
        preICOBalances[0x0D4b2A1a47b1059d622C033c2a58F2F651010553] = 17845264771100000000000;
        preICOFunders.push(0x982F59497026473d2227f5dd02cdf6fdCF237AE0);
        preICOBalances[0x982F59497026473d2227f5dd02cdf6fdCF237AE0] = 31358989521120000000000;
        preICOFunders.push(0x250d540EFeabA7b5C0407A955Fd76217590dbc37);
        preICOBalances[0x250d540EFeabA7b5C0407A955Fd76217590dbc37] = 15000000000000000000000;
        preICOFunders.push(0x2Cde7768B7d5dcb12c5b5572daEf3F7B855c8685);
        preICOBalances[0x2Cde7768B7d5dcb12c5b5572daEf3F7B855c8685] = 17500000000000000000000;
        preICOFunders.push(0x89777c2a4C1843a99B2fF481a4CEF67f5d7A1387);
        preICOBalances[0x89777c2a4C1843a99B2fF481a4CEF67f5d7A1387] = 15000000000000000000000;
        preICOFunders.push(0x63699D4d309e48e8B575BE771700570A828dC655);
        preICOBalances[0x63699D4d309e48e8B575BE771700570A828dC655] = 15000000000000000000000;
        preICOFunders.push(0x9bc92E0da2e4aC174b8E33D7c74b5009563a8e2A);
        preICOBalances[0x9bc92E0da2e4aC174b8E33D7c74b5009563a8e2A] = 21542365440880000000000;
        preICOFunders.push(0xA1CA632CF8Fb3a965c84668e09e3BEdb3567F35D);
        preICOBalances[0xA1CA632CF8Fb3a965c84668e09e3BEdb3567F35D] = 15000000000000000000000;
        preICOFunders.push(0x1DCeF74ddD26c82f34B300E027b5CaA4eC4F8C83);
        preICOBalances[0x1DCeF74ddD26c82f34B300E027b5CaA4eC4F8C83] = 15000000000000000000000;
        preICOFunders.push(0x51B7Bf4B7C1E89cfe7C09938Ad0096F9dFFCA4B7);
        preICOBalances[0x51B7Bf4B7C1E89cfe7C09938Ad0096F9dFFCA4B7] = 17533640761380000000000;

         
        preICOFunders.push(0xD2Cdc0905877ee3b7d08220D783bd042de825AEb);
        preICOBalances[0xD2Cdc0905877ee3b7d08220D783bd042de825AEb] = 5000000000000000000000;
        preICOFunders.push(0x3b217081702AF670e2c2fD25FD7da882620a68E8);
        preICOBalances[0x3b217081702AF670e2c2fD25FD7da882620a68E8] = 7415245400000000000000;
        preICOFunders.push(0xbA860D4B9423bF6b517B29c395A49fe80Da758E3);
        preICOBalances[0xbA860D4B9423bF6b517B29c395A49fe80Da758E3] = 5000000000000000000000;
        preICOFunders.push(0xF64b80DdfB860C0D1bEb760fd9fC663c4D5C4dC3);
        preICOBalances[0xF64b80DdfB860C0D1bEb760fd9fC663c4D5C4dC3] = 75000000000000000000000;
        preICOFunders.push(0x396D5A35B5f41D7cafCCF9BeF225c274d2c7B6E2);
        preICOBalances[0x396D5A35B5f41D7cafCCF9BeF225c274d2c7B6E2] = 74589245777000000000000;
        preICOFunders.push(0x4d61A4aD175E96139Ae8c5d951327e3f6Cc3f764);
        preICOBalances[0x4d61A4aD175E96139Ae8c5d951327e3f6Cc3f764] = 5000000000000000000000;
        preICOFunders.push(0x4B490F6A49C17657A5508B8Bf8F1D7f5aAD8c921);
        preICOBalances[0x4B490F6A49C17657A5508B8Bf8F1D7f5aAD8c921] = 200000000000000000000000;
        preICOFunders.push(0xC943038f2f1dd1faC6E10B82039C14bd20ff1F8E);
        preICOBalances[0xC943038f2f1dd1faC6E10B82039C14bd20ff1F8E] = 174522545811300000000000;
        preICOFunders.push(0xBa87D63A8C4Ed665b6881BaCe4A225a07c418F22);
        preICOBalances[0xBa87D63A8C4Ed665b6881BaCe4A225a07c418F22] = 5000000000000000000000;
        preICOFunders.push(0x753846c0467cF320BcDA9f1C67fF86dF39b1438c);
        preICOBalances[0x753846c0467cF320BcDA9f1C67fF86dF39b1438c] = 5000000000000000000000;
        preICOFunders.push(0x3773bBB1adDF9D642D5bbFaafa13b0690Fb33460);
        preICOBalances[0x3773bBB1adDF9D642D5bbFaafa13b0690Fb33460] = 5000000000000000000000;
        preICOFunders.push(0x456Cf70345cbF483779166af117B40938B8F0A9c);
        preICOBalances[0x456Cf70345cbF483779166af117B40938B8F0A9c] = 50000000000000000000000;
        preICOFunders.push(0x662AE260D736F041Db66c34617d5fB22eC0cC2Ee);
        preICOBalances[0x662AE260D736F041Db66c34617d5fB22eC0cC2Ee] = 40000000000000000000000;
        preICOFunders.push(0xEa7e647F167AdAa4df52AF630A873a1379f68E3F);
        preICOBalances[0xEa7e647F167AdAa4df52AF630A873a1379f68E3F] = 40000000000000000000000;
        preICOFunders.push(0x352913f3F7CA96530180b93C18C86f38b3F0c429);
        preICOBalances[0x352913f3F7CA96530180b93C18C86f38b3F0c429] = 45458265454000000000000;
        preICOFunders.push(0xB21bf8391a6500ED210Af96d125867124261f4d4);
        preICOBalances[0xB21bf8391a6500ED210Af96d125867124261f4d4] = 5000000000000000000000;
        preICOFunders.push(0xDecBd29B42c66f90679D2CB34e73E571F447f6c5);
        preICOBalances[0xDecBd29B42c66f90679D2CB34e73E571F447f6c5] = 7500000000000000000000;
        preICOFunders.push(0xE36106a0DC0F07e87f7194694631511317909b8B);
        preICOBalances[0xE36106a0DC0F07e87f7194694631511317909b8B] = 5000000000000000000000;
        preICOFunders.push(0xe9114cd97E0Ee4fe349D3F57d0C9710E18581b69);
        preICOBalances[0xe9114cd97E0Ee4fe349D3F57d0C9710E18581b69] = 40000000000000000000000;
        preICOFunders.push(0xC73996ce45752B9AE4e85EDDf056Aa9aaCaAD4A2);
        preICOBalances[0xC73996ce45752B9AE4e85EDDf056Aa9aaCaAD4A2] = 100000000000000000000000;
        preICOFunders.push(0x6C1407d9984Dc2cE33456b67acAaEC78c1784673);
        preICOBalances[0x6C1407d9984Dc2cE33456b67acAaEC78c1784673] = 5000000000000000000000;
        preICOFunders.push(0x987e93429004CA9fa2A42604658B99Bb5A574f01);
        preICOBalances[0x987e93429004CA9fa2A42604658B99Bb5A574f01] = 124354548881022000000000;
        preICOFunders.push(0x4c3B81B5f9f9c7efa03bE39218E6760E8D2A1609);
        preICOBalances[0x4c3B81B5f9f9c7efa03bE39218E6760E8D2A1609] = 5000000000000000000000;
        preICOFunders.push(0x33fA8cd89B151458Cb147ecC497e469f2c1D38eA);
        preICOBalances[0x33fA8cd89B151458Cb147ecC497e469f2c1D38eA] = 60000000000000000000000;

         
        preICOFunders.push(0x9AfA1204afCf48AB4302F246Ef4BE5C1D733a751);
        preICOBalances[0x9AfA1204afCf48AB4302F246Ef4BE5C1D733a751] = 154551417972192330000000;
    }

     
    function addFunder(address _funder) public onlyOwner {
        if (!funded[_funder]) {
            funders.push(_funder);
            funded[_funder] = true;
        }
    }
   
     
    function isFunder(address _funder) public view returns(bool) {
        return funded[_funder];
    }

     
    function getFundersCount() public view returns(uint256) {
        return funders.length;
    }

     
    function getPreICOFundersCount() public view returns(uint256) {
        return preICOFunders.length;
    }

     
    function addOrder(
        bytes32 _orderId, 
        address _beneficiary, 
        uint256 _funds, 
        uint256 _bonus
    )
        public 
        onlyOwner 
    {
        orders[_orderId].beneficiary = _beneficiary;
        orders[_orderId].funds = _funds;
        orders[_orderId].bonus = _bonus;
    }

     
    function getOrder(bytes32 _orderId) 
        public 
        view 
        returns(address, uint256, uint256)
    {
        address _beneficiary = orders[_orderId].beneficiary;
        uint256 _funds = orders[_orderId].funds;
        uint256 _bonus = orders[_orderId].bonus;

        return (_beneficiary, _funds, _bonus);
    }

     
    function setRateForOrder(bytes32 _orderId, uint256 _rate) public onlyOwner {
        orders[_orderId].rate = _rate;
    }

     
    function addUnsoldAllocationOrder(bytes32 _orderId) public onlyOwner {
        unsoldAllocationOrders[_orderId] = true;
    }

     
    function addToWhitelist(address _address) public onlyOwner {
        whitelist[_address] = true;
    }

     
    function isWhitelisted(address _address) public view returns(bool) {
        return whitelist[_address];
    }

     
    function getBonus(uint256 _funds, uint256 _bonusChangeTime) public view returns(uint256) {
        
        if (_funds < VOLUME_BONUS_CONDITION)
            return 0;

        if (now < _bonusChangeTime) {  
            if (_funds >= VOLUME_EXTRA_BONUS_CONDITION)
                return FIRST_VOLUME_EXTRA_BONUS;
            else 
                return FIRST_VOLUME_BONUS;
        } else {
            if (_funds >= VOLUME_EXTRA_BONUS_CONDITION)
                return SECOND_VOLUME_EXTRA_BONUS;
            else
                return SECOND_VOLUME_BONUS;
        }
        return 0;
    }
}



 
 

 
pragma solidity ^0.4.18;

contract OraclizeI {
    address public cbAddress;
    function query(uint _timestamp, string _datasource, string _arg) external payable returns (bytes32 _id);
    function query_withGasLimit(uint _timestamp, string _datasource, string _arg, uint _gaslimit) external payable returns (bytes32 _id);
    function query2(uint _timestamp, string _datasource, string _arg1, string _arg2) public payable returns (bytes32 _id);
    function query2_withGasLimit(uint _timestamp, string _datasource, string _arg1, string _arg2, uint _gaslimit) external payable returns (bytes32 _id);
    function queryN(uint _timestamp, string _datasource, bytes _argN) public payable returns (bytes32 _id);
    function queryN_withGasLimit(uint _timestamp, string _datasource, bytes _argN, uint _gaslimit) external payable returns (bytes32 _id);
    function getPrice(string _datasource) public returns (uint _dsprice);
    function getPrice(string _datasource, uint gaslimit) public returns (uint _dsprice);
    function setProofType(byte _proofType) external;
    function setCustomGasPrice(uint _gasPrice) external;
    function randomDS_getSessionPubKeyHash() external constant returns(bytes32);
}
contract OraclizeAddrResolverI {
    function getAddress() public returns (address _addr);
}
contract usingOraclize {
    uint constant day = 60*60*24;
    uint constant week = 60*60*24*7;
    uint constant month = 60*60*24*30;
    byte constant proofType_NONE = 0x00;
    byte constant proofType_TLSNotary = 0x10;
    byte constant proofType_Android = 0x20;
    byte constant proofType_Ledger = 0x30;
    byte constant proofType_Native = 0xF0;
    byte constant proofStorage_IPFS = 0x01;
    uint8 constant networkID_auto = 0;
    uint8 constant networkID_mainnet = 1;
    uint8 constant networkID_testnet = 2;
    uint8 constant networkID_morden = 2;
    uint8 constant networkID_consensys = 161;

    OraclizeAddrResolverI OAR;

    OraclizeI oraclize;
    modifier oraclizeAPI {
        if((address(OAR)==0)||(getCodeSize(address(OAR))==0))
            oraclize_setNetwork(networkID_auto);

        if(address(oraclize) != OAR.getAddress())
            oraclize = OraclizeI(OAR.getAddress());

        _;
    }
    modifier coupon(string code){
        oraclize = OraclizeI(OAR.getAddress());
        _;
    }

    function oraclize_setNetwork(uint8 networkID) internal returns(bool){
      return oraclize_setNetwork();
      networkID;  
    }
    function oraclize_setNetwork() internal returns(bool){
        if (getCodeSize(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed)>0){  
            OAR = OraclizeAddrResolverI(0x1d3B2638a7cC9f2CB3D298A3DA7a90B67E5506ed);
            oraclize_setNetworkName("eth_mainnet");
            return true;
        }
        if (getCodeSize(0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1)>0){  
            OAR = OraclizeAddrResolverI(0xc03A2615D5efaf5F49F60B7BB6583eaec212fdf1);
            oraclize_setNetworkName("eth_ropsten3");
            return true;
        }
        if (getCodeSize(0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e)>0){  
            OAR = OraclizeAddrResolverI(0xB7A07BcF2Ba2f2703b24C0691b5278999C59AC7e);
            oraclize_setNetworkName("eth_kovan");
            return true;
        }
        if (getCodeSize(0x146500cfd35B22E4A392Fe0aDc06De1a1368Ed48)>0){  
            OAR = OraclizeAddrResolverI(0x146500cfd35B22E4A392Fe0aDc06De1a1368Ed48);
            oraclize_setNetworkName("eth_rinkeby");
            return true;
        }
        if (getCodeSize(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475)>0){  
            OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);
            return true;
        }
        if (getCodeSize(0x20e12A1F859B3FeaE5Fb2A0A32C18F5a65555bBF)>0){  
            OAR = OraclizeAddrResolverI(0x20e12A1F859B3FeaE5Fb2A0A32C18F5a65555bBF);
            return true;
        }
        if (getCodeSize(0x51efaF4c8B3C9AfBD5aB9F4bbC82784Ab6ef8fAA)>0){  
            OAR = OraclizeAddrResolverI(0x51efaF4c8B3C9AfBD5aB9F4bbC82784Ab6ef8fAA);
            return true;
        }
        return false;
    }

    function __callback(bytes32 myid, string result) public {
        __callback(myid, result, new bytes(0));
    }
    function __callback(bytes32 myid, string result, bytes proof) public {
      return;
      myid; result; proof;  
    }

    function oraclize_getPrice(string datasource) oraclizeAPI internal returns (uint){
        return oraclize.getPrice(datasource);
    }

    function oraclize_getPrice(string datasource, uint gaslimit) oraclizeAPI internal returns (uint){
        return oraclize.getPrice(datasource, gaslimit);
    }

    function oraclize_query(string datasource, string arg) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0;  
        return oraclize.query.value(price)(0, datasource, arg);
    }
    function oraclize_query(uint timestamp, string datasource, string arg) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0;  
        return oraclize.query.value(price)(timestamp, datasource, arg);
    }
    function oraclize_query(uint timestamp, string datasource, string arg, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0;  
        return oraclize.query_withGasLimit.value(price)(timestamp, datasource, arg, gaslimit);
    }
    function oraclize_query(string datasource, string arg, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0;  
        return oraclize.query_withGasLimit.value(price)(0, datasource, arg, gaslimit);
    }
    function oraclize_query(string datasource, string arg1, string arg2) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0;  
        return oraclize.query2.value(price)(0, datasource, arg1, arg2);
    }
    function oraclize_query(uint timestamp, string datasource, string arg1, string arg2) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0;  
        return oraclize.query2.value(price)(timestamp, datasource, arg1, arg2);
    }
    function oraclize_query(uint timestamp, string datasource, string arg1, string arg2, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0;  
        return oraclize.query2_withGasLimit.value(price)(timestamp, datasource, arg1, arg2, gaslimit);
    }
    function oraclize_query(string datasource, string arg1, string arg2, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0;  
        return oraclize.query2_withGasLimit.value(price)(0, datasource, arg1, arg2, gaslimit);
    }
    function oraclize_query(string datasource, string[] argN) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0;  
        bytes memory args = stra2cbor(argN);
        return oraclize.queryN.value(price)(0, datasource, args);
    }
    function oraclize_query(uint timestamp, string datasource, string[] argN) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0;  
        bytes memory args = stra2cbor(argN);
        return oraclize.queryN.value(price)(timestamp, datasource, args);
    }
    function oraclize_query(uint timestamp, string datasource, string[] argN, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0;  
        bytes memory args = stra2cbor(argN);
        return oraclize.queryN_withGasLimit.value(price)(timestamp, datasource, args, gaslimit);
    }
    function oraclize_query(string datasource, string[] argN, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0;  
        bytes memory args = stra2cbor(argN);
        return oraclize.queryN_withGasLimit.value(price)(0, datasource, args, gaslimit);
    }
    function oraclize_query(string datasource, string[1] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = args[0];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[1] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = args[0];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[1] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = args[0];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, string[1] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](1);
        dynargs[0] = args[0];
        return oraclize_query(datasource, dynargs, gaslimit);
    }

    function oraclize_query(string datasource, string[2] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[2] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[2] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, string[2] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, string[3] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[3] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[3] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, string[3] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(datasource, dynargs, gaslimit);
    }

    function oraclize_query(string datasource, string[4] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[4] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[4] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, string[4] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, string[5] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[5] args) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, string[5] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, string[5] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        string[] memory dynargs = new string[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[] argN) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0;  
        bytes memory args = ba2cbor(argN);
        return oraclize.queryN.value(price)(0, datasource, args);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[] argN) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource);
        if (price > 1 ether + tx.gasprice*200000) return 0;  
        bytes memory args = ba2cbor(argN);
        return oraclize.queryN.value(price)(timestamp, datasource, args);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[] argN, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0;  
        bytes memory args = ba2cbor(argN);
        return oraclize.queryN_withGasLimit.value(price)(timestamp, datasource, args, gaslimit);
    }
    function oraclize_query(string datasource, bytes[] argN, uint gaslimit) oraclizeAPI internal returns (bytes32 id){
        uint price = oraclize.getPrice(datasource, gaslimit);
        if (price > 1 ether + tx.gasprice*gaslimit) return 0;  
        bytes memory args = ba2cbor(argN);
        return oraclize.queryN_withGasLimit.value(price)(0, datasource, args, gaslimit);
    }
    function oraclize_query(string datasource, bytes[1] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = args[0];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[1] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = args[0];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[1] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = args[0];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[1] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](1);
        dynargs[0] = args[0];
        return oraclize_query(datasource, dynargs, gaslimit);
    }

    function oraclize_query(string datasource, bytes[2] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[2] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[2] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[2] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](2);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        return oraclize_query(datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[3] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[3] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[3] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[3] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](3);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        return oraclize_query(datasource, dynargs, gaslimit);
    }

    function oraclize_query(string datasource, bytes[4] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[4] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[4] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[4] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](4);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        return oraclize_query(datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[5] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[5] args) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(timestamp, datasource, dynargs);
    }
    function oraclize_query(uint timestamp, string datasource, bytes[5] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(timestamp, datasource, dynargs, gaslimit);
    }
    function oraclize_query(string datasource, bytes[5] args, uint gaslimit) oraclizeAPI internal returns (bytes32 id) {
        bytes[] memory dynargs = new bytes[](5);
        dynargs[0] = args[0];
        dynargs[1] = args[1];
        dynargs[2] = args[2];
        dynargs[3] = args[3];
        dynargs[4] = args[4];
        return oraclize_query(datasource, dynargs, gaslimit);
    }

    function oraclize_cbAddress() oraclizeAPI internal returns (address){
        return oraclize.cbAddress();
    }
    function oraclize_setProof(byte proofP) oraclizeAPI internal {
        return oraclize.setProofType(proofP);
    }
    function oraclize_setCustomGasPrice(uint gasPrice) oraclizeAPI internal {
        return oraclize.setCustomGasPrice(gasPrice);
    }

    function oraclize_randomDS_getSessionPubKeyHash() oraclizeAPI internal returns (bytes32){
        return oraclize.randomDS_getSessionPubKeyHash();
    }

    function getCodeSize(address _addr) constant internal returns(uint _size) {
        assembly {
            _size := extcodesize(_addr)
        }
    }

    function parseAddr(string _a) internal pure returns (address){
        bytes memory tmp = bytes(_a);
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint i=2; i<2+2*20; i+=2){
            iaddr *= 256;
            b1 = uint160(tmp[i]);
            b2 = uint160(tmp[i+1]);
            if ((b1 >= 97)&&(b1 <= 102)) b1 -= 87;
            else if ((b1 >= 65)&&(b1 <= 70)) b1 -= 55;
            else if ((b1 >= 48)&&(b1 <= 57)) b1 -= 48;
            if ((b2 >= 97)&&(b2 <= 102)) b2 -= 87;
            else if ((b2 >= 65)&&(b2 <= 70)) b2 -= 55;
            else if ((b2 >= 48)&&(b2 <= 57)) b2 -= 48;
            iaddr += (b1*16+b2);
        }
        return address(iaddr);
    }

    function strCompare(string _a, string _b) internal pure returns (int) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;
        if (b.length < minLength) minLength = b.length;
        for (uint i = 0; i < minLength; i ++)
            if (a[i] < b[i])
                return -1;
            else if (a[i] > b[i])
                return 1;
        if (a.length < b.length)
            return -1;
        else if (a.length > b.length)
            return 1;
        else
            return 0;
    }

    function indexOf(string _haystack, string _needle) internal pure returns (int) {
        bytes memory h = bytes(_haystack);
        bytes memory n = bytes(_needle);
        if(h.length < 1 || n.length < 1 || (n.length > h.length))
            return -1;
        else if(h.length > (2**128 -1))
            return -1;
        else
        {
            uint subindex = 0;
            for (uint i = 0; i < h.length; i ++)
            {
                if (h[i] == n[0])
                {
                    subindex = 1;
                    while(subindex < n.length && (i + subindex) < h.length && h[i + subindex] == n[subindex])
                    {
                        subindex++;
                    }
                    if(subindex == n.length)
                        return int(i);
                }
            }
            return -1;
        }
    }

    function strConcat(string _a, string _b, string _c, string _d, string _e) internal pure returns (string) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        for (i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
        for (i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
        for (i = 0; i < _be.length; i++) babcde[k++] = _be[i];
        return string(babcde);
    }

    function strConcat(string _a, string _b, string _c, string _d) internal pure returns (string) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string _a, string _b, string _c) internal pure returns (string) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string _a, string _b) internal pure returns (string) {
        return strConcat(_a, _b, "", "", "");
    }

     
    function parseInt(string _a) internal pure returns (uint) {
        return parseInt(_a, 0);
    }

     
    function parseInt(string _a, uint _b) internal pure returns (uint) {
        bytes memory bresult = bytes(_a);
        uint mint = 0;
        bool decimals = false;
        for (uint i=0; i<bresult.length; i++){
            if ((bresult[i] >= 48)&&(bresult[i] <= 57)){
                if (decimals){
                   if (_b == 0) break;
                    else _b--;
                }
                mint *= 10;
                mint += uint(bresult[i]) - 48;
            } else if (bresult[i] == 46) decimals = true;
        }
        if (_b > 0) mint *= 10**_b;
        return mint;
    }

    function uint2str(uint i) internal pure returns (string){
        if (i == 0) return "0";
        uint j = i;
        uint len;
        while (j != 0){
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (i != 0){
            bstr[k--] = byte(48 + i % 10);
            i /= 10;
        }
        return string(bstr);
    }

    function stra2cbor(string[] arr) internal pure returns (bytes) {
            uint arrlen = arr.length;

             
            uint outputlen = 0;
            bytes[] memory elemArray = new bytes[](arrlen);
            for (uint i = 0; i < arrlen; i++) {
                elemArray[i] = (bytes(arr[i]));
                outputlen += elemArray[i].length + (elemArray[i].length - 1)/23 + 3;  
            }
            uint ctr = 0;
            uint cborlen = arrlen + 0x80;
            outputlen += byte(cborlen).length;
            bytes memory res = new bytes(outputlen);

            while (byte(cborlen).length > ctr) {
                res[ctr] = byte(cborlen)[ctr];
                ctr++;
            }
            for (i = 0; i < arrlen; i++) {
                res[ctr] = 0x5F;
                ctr++;
                for (uint x = 0; x < elemArray[i].length; x++) {
                     
                    if (x % 23 == 0) {
                        uint elemcborlen = elemArray[i].length - x >= 24 ? 23 : elemArray[i].length - x;
                        elemcborlen += 0x40;
                        uint lctr = ctr;
                        while (byte(elemcborlen).length > ctr - lctr) {
                            res[ctr] = byte(elemcborlen)[ctr - lctr];
                            ctr++;
                        }
                    }
                    res[ctr] = elemArray[i][x];
                    ctr++;
                }
                res[ctr] = 0xFF;
                ctr++;
            }
            return res;
        }

    function ba2cbor(bytes[] arr) internal pure returns (bytes) {
            uint arrlen = arr.length;

             
            uint outputlen = 0;
            bytes[] memory elemArray = new bytes[](arrlen);
            for (uint i = 0; i < arrlen; i++) {
                elemArray[i] = (bytes(arr[i]));
                outputlen += elemArray[i].length + (elemArray[i].length - 1)/23 + 3;  
            }
            uint ctr = 0;
            uint cborlen = arrlen + 0x80;
            outputlen += byte(cborlen).length;
            bytes memory res = new bytes(outputlen);

            while (byte(cborlen).length > ctr) {
                res[ctr] = byte(cborlen)[ctr];
                ctr++;
            }
            for (i = 0; i < arrlen; i++) {
                res[ctr] = 0x5F;
                ctr++;
                for (uint x = 0; x < elemArray[i].length; x++) {
                     
                    if (x % 23 == 0) {
                        uint elemcborlen = elemArray[i].length - x >= 24 ? 23 : elemArray[i].length - x;
                        elemcborlen += 0x40;
                        uint lctr = ctr;
                        while (byte(elemcborlen).length > ctr - lctr) {
                            res[ctr] = byte(elemcborlen)[ctr - lctr];
                            ctr++;
                        }
                    }
                    res[ctr] = elemArray[i][x];
                    ctr++;
                }
                res[ctr] = 0xFF;
                ctr++;
            }
            return res;
        }


    string oraclize_network_name;
    function oraclize_setNetworkName(string _network_name) internal {
        oraclize_network_name = _network_name;
    }

    function oraclize_getNetworkName() internal view returns (string) {
        return oraclize_network_name;
    }

    function oraclize_newRandomDSQuery(uint _delay, uint _nbytes, uint _customGasLimit) internal returns (bytes32){
        require((_nbytes > 0) && (_nbytes <= 32));
        bytes memory nbytes = new bytes(1);
        nbytes[0] = byte(_nbytes);
        bytes memory unonce = new bytes(32);
        bytes memory sessionKeyHash = new bytes(32);
        bytes32 sessionKeyHash_bytes32 = oraclize_randomDS_getSessionPubKeyHash();
        assembly {
            mstore(unonce, 0x20)
            mstore(add(unonce, 0x20), xor(blockhash(sub(number, 1)), xor(coinbase, timestamp)))
            mstore(sessionKeyHash, 0x20)
            mstore(add(sessionKeyHash, 0x20), sessionKeyHash_bytes32)
        }
        bytes[3] memory args = [unonce, nbytes, sessionKeyHash];
        bytes32 queryId = oraclize_query(_delay, "random", args, _customGasLimit);
        oraclize_randomDS_setCommitment(queryId, keccak256(bytes8(_delay), args[1], sha256(args[0]), args[2]));
        return queryId;
    }

    function oraclize_randomDS_setCommitment(bytes32 queryId, bytes32 commitment) internal {
        oraclize_randomDS_args[queryId] = commitment;
    }

    mapping(bytes32=>bytes32) oraclize_randomDS_args;
    mapping(bytes32=>bool) oraclize_randomDS_sessionKeysHashVerified;

    function verifySig(bytes32 tosignh, bytes dersig, bytes pubkey) internal returns (bool){
        bool sigok;
        address signer;

        bytes32 sigr;
        bytes32 sigs;

        bytes memory sigr_ = new bytes(32);
        uint offset = 4+(uint(dersig[3]) - 0x20);
        sigr_ = copyBytes(dersig, offset, 32, sigr_, 0);
        bytes memory sigs_ = new bytes(32);
        offset += 32 + 2;
        sigs_ = copyBytes(dersig, offset+(uint(dersig[offset-1]) - 0x20), 32, sigs_, 0);

        assembly {
            sigr := mload(add(sigr_, 32))
            sigs := mload(add(sigs_, 32))
        }


        (sigok, signer) = safer_ecrecover(tosignh, 27, sigr, sigs);
        if (address(keccak256(pubkey)) == signer) return true;
        else {
            (sigok, signer) = safer_ecrecover(tosignh, 28, sigr, sigs);
            return (address(keccak256(pubkey)) == signer);
        }
    }

    function oraclize_randomDS_proofVerify__sessionKeyValidity(bytes proof, uint sig2offset) internal returns (bool) {
        bool sigok;

         
        bytes memory sig2 = new bytes(uint(proof[sig2offset+1])+2);
        copyBytes(proof, sig2offset, sig2.length, sig2, 0);

        bytes memory appkey1_pubkey = new bytes(64);
        copyBytes(proof, 3+1, 64, appkey1_pubkey, 0);

        bytes memory tosign2 = new bytes(1+65+32);
        tosign2[0] = byte(1);  
        copyBytes(proof, sig2offset-65, 65, tosign2, 1);
        bytes memory CODEHASH = hex"fd94fa71bc0ba10d39d464d0d8f465efeef0a2764e3887fcc9df41ded20f505c";
        copyBytes(CODEHASH, 0, 32, tosign2, 1+65);
        sigok = verifySig(sha256(tosign2), sig2, appkey1_pubkey);

        if (sigok == false) return false;


         
        bytes memory LEDGERKEY = hex"7fb956469c5c9b89840d55b43537e66a98dd4811ea0a27224272c2e5622911e8537a2f8e86a46baec82864e98dd01e9ccc2f8bc5dfc9cbe5a91a290498dd96e4";

        bytes memory tosign3 = new bytes(1+65);
        tosign3[0] = 0xFE;
        copyBytes(proof, 3, 65, tosign3, 1);

        bytes memory sig3 = new bytes(uint(proof[3+65+1])+2);
        copyBytes(proof, 3+65, sig3.length, sig3, 0);

        sigok = verifySig(sha256(tosign3), sig3, LEDGERKEY);

        return sigok;
    }

    modifier oraclize_randomDS_proofVerify(bytes32 _queryId, string _result, bytes _proof) {
         
        require((_proof[0] == "L") && (_proof[1] == "P") && (_proof[2] == 1));

        bool proofVerified = oraclize_randomDS_proofVerify__main(_proof, _queryId, bytes(_result), oraclize_getNetworkName());
        require(proofVerified);

        _;
    }

    function oraclize_randomDS_proofVerify__returnCode(bytes32 _queryId, string _result, bytes _proof) internal returns (uint8){
         
        if ((_proof[0] != "L")||(_proof[1] != "P")||(_proof[2] != 1)) return 1;

        bool proofVerified = oraclize_randomDS_proofVerify__main(_proof, _queryId, bytes(_result), oraclize_getNetworkName());
        if (proofVerified == false) return 2;

        return 0;
    }

    function matchBytes32Prefix(bytes32 content, bytes prefix, uint n_random_bytes) internal pure returns (bool){
        bool match_ = true;


        for (uint256 i=0; i< n_random_bytes; i++) {
            if (content[i] != prefix[i]) match_ = false;
        }

        return match_;
    }

    function oraclize_randomDS_proofVerify__main(bytes proof, bytes32 queryId, bytes result, string context_name) internal returns (bool){

         
        uint ledgerProofLength = 3+65+(uint(proof[3+65+1])+2)+32;
        bytes memory keyhash = new bytes(32);
        copyBytes(proof, ledgerProofLength, 32, keyhash, 0);
        if (!(keccak256(keyhash) == keccak256(sha256(context_name, queryId)))) return false;

        bytes memory sig1 = new bytes(uint(proof[ledgerProofLength+(32+8+1+32)+1])+2);
        copyBytes(proof, ledgerProofLength+(32+8+1+32), sig1.length, sig1, 0);

         
        if (!matchBytes32Prefix(sha256(sig1), result, uint(proof[ledgerProofLength+32+8]))) return false;

         
         
        bytes memory commitmentSlice1 = new bytes(8+1+32);
        copyBytes(proof, ledgerProofLength+32, 8+1+32, commitmentSlice1, 0);

        bytes memory sessionPubkey = new bytes(64);
        uint sig2offset = ledgerProofLength+32+(8+1+32)+sig1.length+65;
        copyBytes(proof, sig2offset-64, 64, sessionPubkey, 0);

        bytes32 sessionPubkeyHash = sha256(sessionPubkey);
        if (oraclize_randomDS_args[queryId] == keccak256(commitmentSlice1, sessionPubkeyHash)){  
            delete oraclize_randomDS_args[queryId];
        } else return false;


         
        bytes memory tosign1 = new bytes(32+8+1+32);
        copyBytes(proof, ledgerProofLength, 32+8+1+32, tosign1, 0);
        if (!verifySig(sha256(tosign1), sig1, sessionPubkey)) return false;

         
        if (oraclize_randomDS_sessionKeysHashVerified[sessionPubkeyHash] == false){
            oraclize_randomDS_sessionKeysHashVerified[sessionPubkeyHash] = oraclize_randomDS_proofVerify__sessionKeyValidity(proof, sig2offset);
        }

        return oraclize_randomDS_sessionKeysHashVerified[sessionPubkeyHash];
    }

     
    function copyBytes(bytes from, uint fromOffset, uint length, bytes to, uint toOffset) internal pure returns (bytes) {
        uint minLength = length + toOffset;

         
        require(to.length >= minLength);  

         
        uint i = 32 + fromOffset;
        uint j = 32 + toOffset;

        while (i < (32 + fromOffset + length)) {
            assembly {
                let tmp := mload(add(from, i))
                mstore(add(to, j), tmp)
            }
            i += 32;
            j += 32;
        }

        return to;
    }

     
     
    function safer_ecrecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal returns (bool, address) {
         
         
         
         
         

         
        bool ret;
        address addr;

        assembly {
            let size := mload(0x40)
            mstore(size, hash)
            mstore(add(size, 32), v)
            mstore(add(size, 64), r)
            mstore(add(size, 96), s)

             
             
            ret := call(3000, 1, 0, size, 128, size, 32)
            addr := mload(size)
        }

        return (ret, addr);
    }

     
    function ecrecovery(bytes32 hash, bytes sig) internal returns (bool, address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (sig.length != 65)
          return (false, 0);

         
         
         
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))

             
             
             
            v := byte(0, mload(add(sig, 96)))

             
             
             
             
        }

         
         
         
         
         
        if (v < 27)
          v += 27;

        if (v != 27 && v != 28)
            return (false, 0);

        return safer_ecrecover(hash, v, r, s);
    }

}
 



 
contract BetexICO is usingOraclize, HasNoContracts {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

     
    BetexToken public token;

     
    BetexStorage public betexStorage;

     
    uint256 public startTime;

     
    uint256 public bonusChangeTime;

     
    uint256 public endTime;

     
    address public wallet;

     
    uint256 public sold;

     
    uint256 public raised;

     
    uint256 public unsoldTokensAmount;

     
    uint256 public soldBeforeUnsoldAllocation;

     
    uint256 public unsoldAllocationCount;

     
    bool public preICOTokensAllocated;

     
    bool public unsoldAllocatonScheduled;

     
    string public ethRateURL = "json(https://api.coinmarketcap.com/v1/ticker/ethereum/).0.price_usd";

     
    uint256 public oraclizeGasLimit = 200000;

     
    uint256 public unsoldAllocationOraclizeGasLimit = 2500000;

     
    uint256 public unsoldAllocationDelay = 10800;

     
    mapping (address => bool) public refillers;

     
    uint256 public constant MIN_FUNDING_AMOUNT = 0.5 ether;

     
    uint256 public constant RATE_EXPONENT = 4;

     
    uint256 public constant TOKEN_PRICE = 3;

     
    uint256 public constant UNSOLD_ALLOCATION_SIZE = 50; 

     
    uint256 public constant UNSOLD_ALLOCATION_EXPONENT = 10;

     
    event WhitelistAddEvent(address indexed funder);

     
    event OrderEvent(address indexed funder, bytes32 indexed orderId, uint256 funds);

     
    event TokenPurchaseEvent(address indexed funder, bytes32 indexed orderId, uint256 tokens);

     
    event UnsoldTokensAllocationEvent(address indexed funder, uint256 tokens);


     
    function BetexICO (
        uint256 _startTime,
        uint256 _bonusChangeTime,
        uint256 _endTime,
        address _wallet, 
        address _token,
        address _betexStorage
    ) 
        public 
        payable
    {
        require(_startTime < _endTime);
        require(_bonusChangeTime > _startTime && _bonusChangeTime < _endTime);

        require(_wallet != address(0));
        require(_token != address(0));
        require(_betexStorage != address(0));

        startTime = _startTime;
        bonusChangeTime = _bonusChangeTime;
        endTime = _endTime;
        wallet = _wallet;

        token = BetexToken(_token);
        betexStorage = BetexStorage(_betexStorage);
    }

     
    function () public payable {
        address _sender = msg.sender;
        uint256 _funds = msg.value;

        if (betexStorage.isWhitelisted(_sender)) {
            buyTokens(_sender, _funds);
        } else if (!refillers[_sender] && !(owner == _sender)) {
            revert();
        }
    }

     
    function __callback(bytes32 _orderId, string _result) public {   
        require(msg.sender == oraclize_cbAddress());

         
        if (betexStorage.unsoldAllocationOrders(_orderId)) {
            if (!allUnsoldTokensAllocated()) {
                allocateUnsoldTokens();
                if (!allUnsoldTokensAllocated()) {
                    bytes32 orderId = oraclize_query("URL", ethRateURL, unsoldAllocationOraclizeGasLimit);
                    betexStorage.addUnsoldAllocationOrder(orderId);
                }
            }
        } else {
            uint256 _rate = parseInt(_result, RATE_EXPONENT);

            address _beneficiary;
            uint256 _funds;
            uint256 _bonus;

            (_beneficiary, _funds, _bonus) = betexStorage.getOrder(_orderId);

            uint256 _sum = _funds.mul(_rate).div(10 ** RATE_EXPONENT);
            uint256 _tokens = _sum.div(TOKEN_PRICE);

            uint256 _bonusTokens = _tokens.mul(_bonus).div(100);
            _tokens = _tokens.add(_bonusTokens);

            if (sold.add(_tokens) > token.SALE_SUPPLY()) {
                _tokens = token.SALE_SUPPLY().sub(sold);
            }

            betexStorage.setRateForOrder(_orderId, _rate);

            token.transfer(_beneficiary, _tokens);
            sold = sold.add(_tokens);
            emit TokenPurchaseEvent(_beneficiary, _orderId, _tokens);
        }
    }

     
    function scheduleUnsoldAllocation() public {
        require(!unsoldAllocatonScheduled);

         
        bytes32 _orderId = oraclize_query(endTime.add(unsoldAllocationDelay), "URL", ethRateURL, unsoldAllocationOraclizeGasLimit);  
        betexStorage.addUnsoldAllocationOrder(_orderId); 

        unsoldAllocatonScheduled = true;
    }

     
    function allocateUnsoldTokens() public {
        require(now > endTime.add(unsoldAllocationDelay));  
        require(!allUnsoldTokensAllocated());

         
        if (unsoldAllocationCount == 0) {
            unsoldTokensAmount = token.SALE_SUPPLY().sub(sold);
            soldBeforeUnsoldAllocation = sold;
        }

        for (uint256 i = 0; i < UNSOLD_ALLOCATION_SIZE && !allUnsoldTokensAllocated(); i = i.add(1)) {
            address _funder = betexStorage.funders(unsoldAllocationCount);
            uint256 _funderTokens = token.balanceOf(_funder);

            if (_funderTokens != 0) {
                uint256 _share = _funderTokens.mul(10 ** UNSOLD_ALLOCATION_EXPONENT).div(soldBeforeUnsoldAllocation);
                uint256 _tokensToAllocate = unsoldTokensAmount.mul(_share).div(10 ** UNSOLD_ALLOCATION_EXPONENT);

                token.transfer(_funder, _tokensToAllocate); 
                emit UnsoldTokensAllocationEvent(_funder, _tokensToAllocate);
                sold = sold.add(_tokensToAllocate);
            }

            unsoldAllocationCount = unsoldAllocationCount.add(1);
        }

        if (allUnsoldTokensAllocated()) {
            if (sold < token.SALE_SUPPLY()) {
                uint256 _change = token.SALE_SUPPLY().sub(sold);
                address _reserveAddress = token.RESERVE_ADDRESS();
                token.transfer(_reserveAddress, _change);
                sold = sold.add(_change);
            }
        }           
    }

     
    function allocatePreICOTokens() public {
        require(!preICOTokensAllocated);

        for (uint256 i = 0; i < betexStorage.getPreICOFundersCount(); i++) {
            address _funder = betexStorage.preICOFunders(i);
            uint256 _tokens = betexStorage.preICOBalances(_funder);

            token.transfer(_funder, _tokens);
            sold = sold.add(_tokens);

            betexStorage.addFunder(_funder);
        }
        
        preICOTokensAllocated = true;
    }

     
    function addToWhitelist(address _funder) onlyOwner public {
        require(_funder != address(0));
        betexStorage.addToWhitelist(_funder);

        emit WhitelistAddEvent(_funder);
    }

     
    function setOraclizeGasLimit(uint256 _gasLimit) onlyOwner public {
        require(_gasLimit > 0);
        oraclizeGasLimit = _gasLimit;
    }

     
    function setOraclizeGasPrice(uint256 _gasPrice) onlyOwner public {
        require(_gasPrice > 0);
        oraclize_setCustomGasPrice(_gasPrice);
    }

     
    function addRefiller(address _refiller) onlyOwner public {
        require(_refiller != address(0));
        refillers[_refiller] = true;
    }

     
    function withdrawEther(uint256 _amount) onlyOwner public {
        require(address(this).balance >= _amount);
        owner.transfer(_amount);
    }

     
    function buyTokens(address _funder, uint256 _funds) internal {
        require(liveBetexICO());
        require(_funds >= MIN_FUNDING_AMOUNT);
        require(oraclize_getPrice("URL") <= address(this).balance);
        
        bytes32 _orderId = oraclize_query("URL", ethRateURL, oraclizeGasLimit);
        uint256 _bonus = betexStorage.getBonus(_funds, bonusChangeTime);
        betexStorage.addOrder(_orderId, _funder, _funds, _bonus);  

        wallet.transfer(_funds);
        raised = raised.add(_funds);

        betexStorage.addFunder(_funder);

        emit OrderEvent(_funder, _orderId, _funds);
    }

     
    function allUnsoldTokensAllocated() internal view returns (bool) {
        return unsoldAllocationCount == betexStorage.getFundersCount();
    }

     
    function liveBetexICO() internal view returns (bool) {
        return now >= startTime && now <= endTime && sold < token.SALE_SUPPLY();  
    }
    
}