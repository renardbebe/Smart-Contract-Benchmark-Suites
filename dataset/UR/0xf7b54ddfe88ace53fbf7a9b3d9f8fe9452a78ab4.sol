 

pragma solidity ^0.4.17;

 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
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

     
    function Ownable() {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

}

contract Fund is Ownable  {
    using SafeMath for uint256;
    
    string public name = "Slot Token";
    uint8 public decimals = 0;
    string public symbol = "SLOT";
    string public version = "0.7";
    
    uint8 constant TOKENS = 0;
    uint8 constant BALANCE = 1;
    
    uint256 totalWithdrawn;      
    uint256 public totalSupply;  
    
    mapping(address => uint256[2][]) balances;
    mapping(address => uint256) withdrawals;
    
    event Withdrawn(
            address indexed investor, 
            address indexed beneficiary, 
            uint256 weiAmount);
    event Mint(
            address indexed to, 
            uint256 amount);
    event MintFinished();
    event Transfer(
            address indexed from, 
            address indexed to, 
            uint256 value);
    event Approval(
            address indexed owner, 
            address indexed spender, 
            uint256 value);
            
    mapping (address => mapping (address => uint256)) allowed;

    bool public mintingFinished = false;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }
    
    function Fund() payable {}
    function() payable {}
    
    function getEtherBalance(address _owner) constant public returns (uint256 _balance) {
        uint256[2][] memory snapshots = balances[_owner];
        
        if (snapshots.length == 0) { return 0; }  

        uint256 balance = 0;
        uint256 previousSnapTotalStake = 0;
        
         
        for (uint256 i = 0 ; i < snapshots.length ; i++) {
             
            
            if (i == snapshots.length-1) {
                 
                uint256 currentTokens = snapshots[i][TOKENS];
                uint256 b = currentTokens.mul( getTotalStake().sub(previousSnapTotalStake) ).div(totalSupply);
                balance = balance.add(b);
        
                 
                return balance.sub(withdrawals[_owner]);
            }
            
            uint256 snapTotalStake = snapshots[i][BALANCE];
             
            uint256 spanBalance = snapshots[i][TOKENS].mul(snapTotalStake.sub(previousSnapTotalStake)).div(totalSupply);
            balance = balance.add(spanBalance);
            
            previousSnapTotalStake = previousSnapTotalStake.add(snapTotalStake);  
        }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        uint256[2][] memory snapshots = balances[_owner];
        if (snapshots.length == 0) { return 0; }
        
        return snapshots[snapshots.length-1][TOKENS];
    }
    
    function getTotalStake() constant public returns (uint256 _totalStake) {
         
        return this.balance + totalWithdrawn;
    }
    
    function withdrawBalance(address _to, uint256 _value) public {
        require(getEtherBalance(msg.sender) >= _value);
        
        withdrawals[msg.sender] = withdrawals[msg.sender].add(_value);
        totalWithdrawn = totalWithdrawn.add(_value);
        
        _to.transfer(_value);
        Withdrawn(msg.sender, _to, _value);
    }
    
    function transfer(address _to, uint256 _value) returns (bool) {
        return transferFromPrivate(msg.sender, _to, _value);
    }
    
    function transferFromPrivate(address _from, address _to, uint256 _value) private returns (bool) {
        require(balanceOf(msg.sender) >= _value);
        
        uint256 fromTokens = balanceOf(msg.sender);
        pushSnapshot(msg.sender, fromTokens-_value);
        
        uint256 toTokens = balanceOf(_to);
        pushSnapshot(_to, toTokens+_value);
        
        Transfer(_from, _to, _value);
        return true;
    }
    
    function pushSnapshot(address _beneficiary, uint256 _amount) private {
        balances[_beneficiary].push([_amount, 0]);
        
        if (balances[_beneficiary].length > 1) {
             
            uint256 lastIndex = balances[msg.sender].length-1;
            balances[_beneficiary][lastIndex-1][BALANCE] = getTotalStake();
        }
    }

    function mint(address _to, uint256 _amount) public onlyOwner canMint returns (bool) {
        pushSnapshot(_to, _amount.add(balanceOf(_to)));
        totalSupply = totalSupply.add(_amount);
        Mint(_to, _amount);
        Transfer(0x0, _to, _amount);  
        return true;
    }
    

    function finishMinting() onlyOwner returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }
    
    
    function approve(address _spender, uint256 _value) returns (bool) {

         
         
         
         
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
        uint256 _allowance = allowed[_from][msg.sender];

        transferFromPrivate(_from, _to, _value);
        
        allowed[_from][msg.sender] = _allowance.sub(_value);
        return true;
    }
    
}

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;

   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused returns (bool) {
    paused = true;
    Pause();
    return true;
  }

   
  function unpause() onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}


 
contract SlotCrowdsale is Ownable, Pausable {
    using SafeMath for uint256;

    Fund public fund;

    uint256 constant ETHER_CAP   = 4715 ether;    
    uint256 constant TOKEN_CAP   = 10000000;      
    uint256 constant PRICE       = 1 ether;       
    uint256 constant BOUNTY      = 250000;        
    uint256 constant OWNERS_STAKE = 3750000;      
    uint256 constant OWNERS_LOCK = 200000;        
    address public bountyWallet;
    address public ownersWallet;
    uint256 public lockBegunAtBlock;
    
    bool public bountyDistributed = false;
    bool public ownershipDistributed = false;
    
    uint256[10] outcomes = [1000000,     
                             250000,     
                             100000,     
                              20000,     
                              10000,     
                               4000,     
                               2000,     
                               1250,     
                               1000,     
                                500];    
                               
                             
    uint16[10] chances =        [1, 4, 10, 50, 100, 250, 500,  800, 1000, 2000];
    uint16[10] addedUpChances = [1, 5, 15, 65, 165, 415, 915, 1715, 2715, 4715];
    
    event OwnershipDistributed();
    event BountyDistributed();

    function SlotCrowdsale() payable {
         
        fund = new Fund();
        bountyWallet = 0x00deF93928A3aAD581F39049a3BbCaaB9BbE36C8;
        ownersWallet = 0x0001619153d8FE15B3FA70605859265cb0033c1a;
    }

    function() payable {
         
        buyTokenFor(msg.sender);
    }
    
    function correctedIndex(uint8 _index) constant private returns (uint8 _newIndex) {
        require(_index < chances.length);
         
        
        if (chances[_index] != 0) {
            return _index;
        } else {
            return correctedIndex(uint8((_index + 1) % chances.length));
        }
    }
    
    function getRateIndex(uint256 _randomNumber) constant private returns (uint8 _rateIndex) {
        for (uint8 i = 0 ; i < uint8(chances.length) ; i++) {
            if (_randomNumber < addedUpChances[i]) { 
                return correctedIndex(i); 
            }
        }
    }

    function buyTokenFor(address _beneficiary) whenNotPaused() payable {
        require(_beneficiary != 0x0);
        require(msg.value >= PRICE);
        
        uint256 change = msg.value%PRICE;
        uint256 numberOfTokens = msg.value.sub(change).div(PRICE);
        
        mintTokens(_beneficiary, numberOfTokens);
        
         
        msg.sender.transfer(change);
    }
    
    function mintTokens(address _beneficiary, uint256 _numberOfTokens) private {
        uint16 totalChances = addedUpChances[9];

        for (uint16 i=1 ; i <= _numberOfTokens; i++) {
            
            uint256 randomNumber = uint256(keccak256(block.blockhash(block.number-1)))%totalChances;
            uint8 rateIndex = getRateIndex(randomNumber);
            
             
            assert(chances[rateIndex] != 0);
            chances[rateIndex]--;
            
            uint256 amount = outcomes[rateIndex];
            fund.mint(_beneficiary, amount);
        }
    }
    
    function crowdsaleEnded() constant private returns (bool ended) {
        if (fund.totalSupply() >= TOKEN_CAP) { 
            return true;
        } else {
            return false; 
        }
    }
    
    function lockEnded() constant private returns (bool ended) {
        if (block.number.sub(lockBegunAtBlock) > OWNERS_LOCK) {
            return true; 
        } else {
            return false;
        }
        
    }
    
     
    
    function distributeBounty() public onlyOwner {
        require(!bountyDistributed);
        require(crowdsaleEnded());
        
        bountyDistributed = true;
        bountyWallet.transfer(BOUNTY);
        lockBegunAtBlock = block.number;
        BountyDistributed();
    }
    
    function distributeOwnership() public onlyOwner {
        require(!ownershipDistributed);
        require(crowdsaleEnded());
        require(lockEnded());
        
        ownershipDistributed = true;
        ownersWallet.transfer(OWNERS_STAKE);
        
        OwnershipDistributed();
    }
    
    function changeOwnersWallet(address _newWallet) public onlyOwner {
        require(_newWallet != 0x0);
        ownersWallet = _newWallet;
    }
    
    function changeBountyWallet(address _newWallet) public onlyOwner {
        require(_newWallet != 0x0);
        bountyWallet = _newWallet;
    }
    
    function changeFundOwner(address _newOwner) {
        require(_newOwner != 0x0);
        fund.transferOwnership(_newOwner);
    }

}