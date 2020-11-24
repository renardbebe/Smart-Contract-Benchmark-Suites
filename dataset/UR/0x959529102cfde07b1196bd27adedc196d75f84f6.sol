 

pragma solidity ^0.4.19;
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
contract BLO{
    using SafeMath for uint256;

    uint256 constant MAX_UINT256 = 2**256 - 1;
    uint256 _initialAmount = 0;
    address  public contract_owner;
    uint256 public exchangeRate = 7000;                     
    bool public icoOpen = false;                            

    uint256 public publicToken = 110000000;                 
    uint256 public bountyToken = 12070000;                  
    uint256 public airdropToken = 50430000 + 2500000;       
    uint256 public reserveMember = 6450000;                 
    uint256 public reservedFounder = 12000000;              

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

     
    struct lock {
        uint256 amount;
        uint256 duration;    
    }    
     
    struct founderLock {
        uint256 amount;
        uint256 startTime;
        uint remainRound;
        uint totalRound;
        uint256 period;
    }
    
    mapping (address => lock) public lockance;
    mapping (address => founderLock) public founderLockance;
    

    
     
    event Transfer(address indexed _from, address indexed _to, uint256 _value); 
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Unlock(address _sender, uint256 _amount);
    event FounderUnlock(address _sender, uint256 _amount);
    
    
    
    
     
    string public name = "PABLOCoin";                    
    uint8 public decimals = 0;                 
    string public symbol = "BLO";                  

     
      modifier onlyPayloadSize(uint size) {
          require(msg.data.length >= size + 4);
          _;
      }
      modifier  onlyOwner() { 
          require(msg.sender == contract_owner); 
          _; 
      }
      modifier inIco() { 
          require(icoOpen==true); 
          _; 
      }
      
      

    function BLO() public {
         
        contract_owner = msg.sender;

         
        address Wayne = 0x1A33cDA3cF3d9b7318B105171115F799ac3e986D;
        address Sophie = 0xd4AFd732Da602Fc44e99B4c3285B46D9369F2Beb;
        address Calvin = 0xa34cB9F691B939b7C137CaC3C11907c9bE5F7Ae9;
        address Marsh = 0x042bD518576C7fEDF26870D7C65f9ff2597c9935;
        address Chris = 0x050992436F5048F5C5B48Db0e8593DE48521b35A;
        address Josh = 0x11ae09350b18ea810bc7fd6892612a63c641d641;
        address LM = 0x8Dd1cDD513b05D07726a6F8C75b57602991a9c34;
        address TJ = 0xdd36FBf1C0A63759892FeAE493f4AaB9dc23cE54;
        address Chuck1 = 0xb5d93E0cE63E7B7cE8fD5A89e8a7E217721Ad5Fa;
        address Chuck2 = 0xE76c0618Dd52403ad1907D3BCbF930226bFEa46B;
        address Tom1 = 0x52103e8bbDfcFB49d978CE8F4a0b862e0F14dC7E;
        address Tom2 = 0xeF2f04dbd3E3aD126979646383c94Fd29E29de9F;

        balances[msg.sender] += 1000000/2;
        transfer(Wayne, 1000000/2);
        setLock(Wayne, 1000000/2, 60 days);
        _initialAmount += 1000000;

        balances[msg.sender] += 1000000/2;
        transfer(Sophie, 1000000/2);
        setLock(Sophie, 1000000/2, 60 days);
        _initialAmount += 1000000;

        balances[msg.sender] += 1000000/2;
        transfer(Calvin, 1000000/2);
        setLock(Calvin, 1000000/2, 60 days);
        _initialAmount += 1000000;

        balances[msg.sender] += 2600000/2;
        transfer(Marsh, 2600000/2);
        setLock(Marsh, 2600000/2, 60 days);
        _initialAmount += 2600000;

        balances[msg.sender] += 50000/2;
        transfer(Chris, 50000/2);
        setLock(Chris, 50000/2, 60 days);
        _initialAmount += 50000;

        balances[msg.sender] += 1000000/2;
        transfer(Josh, 1000000/2);
        setLock(Josh, 1000000/2, 60 days);
        _initialAmount += 1000000;

        balances[msg.sender] += 5100000/2;
        transfer(LM, 5100000/2);
        setLock(LM, 5100000/2, 60 days);
        _initialAmount += 5100000;

        balances[msg.sender] += 1800000/2;
        transfer(TJ, 1800000/2);
        setLock(TJ, 1800000/2, 60 days);
        _initialAmount += 1800000;

        balances[msg.sender] += 9000000;
        transfer(Chuck1, 9000000);
        setFounderLock(Chuck2, 12500000, 6, 180 days);
        _initialAmount += 12500000 + 9000000;

        balances[msg.sender] += 9000000;
        transfer(Tom1, 9000000);
        setFounderLock(Tom2, 12500000, 6, 180 days);
        _initialAmount += 12500000 + 9000000;
    }
    function totalSupply() constant returns (uint256 _totalSupply){
        _totalSupply = _initialAmount;
      }
    function transfer(address _to, uint256 _value) public returns (bool success) {
         
         
         
         
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
        }
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
         
         
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        Transfer(_from, _to, _value);
        return true;
        }

    function balanceOf(address _owner) view public returns (uint256 balance) {
        return balances[_owner];
        }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
        }

    function allowance(address _owner, address _spender)
    view public returns (uint256 remaining) {
      return allowed[_owner][_spender];
        }

    function multisend(address[] addrs,  uint256 _value)
    {
        uint length = addrs.length;
        require(_value * length <= balances[msg.sender]);
        uint i = 0;
        while (i < length) {
           transfer(addrs[i], _value);
           i ++;
        }
        
      }
    function multAirdrop(address[] addrs,  uint256 _value) onlyOwner
    {
        uint length = addrs.length;
        uint256 totalToken = _value * length;
        require(totalToken <= airdropToken);
        balances[contract_owner] += totalToken;
        uint i = 0;
        while (i < length) {
           transfer(addrs[i], _value);
           i ++;
        }
        _initialAmount += totalToken;
        airdropToken -= totalToken;
        
      }
     
     
     
     
    function setLock(address _address, uint256 _value, uint256 _time) internal onlyOwner {
        lockance[_address].amount = _value;
        lockance[_address].duration = now + _time;
      }
    
     
     
     
     
     
    function setFounderLock(address _address, uint256 _value, uint _round, uint256 _period)  internal onlyOwner{
        founderLockance[_address].amount = _value.div(_round);
        founderLockance[_address].startTime = now;
        founderLockance[_address].remainRound = _round;
        founderLockance[_address].totalRound = _round;
        founderLockance[_address].period = _period;
    }
    
     
    function unlock () {
        require(now >= lockance[msg.sender].duration);
        uint256 _amount = lockance[msg.sender].amount;
        balances[msg.sender] += lockance[msg.sender].amount;
        lockance[msg.sender].amount = 0;
        Unlock(msg.sender, _amount);
    }
     
    function unlockFounder (uint _round) {
        require(now >= founderLockance[msg.sender].startTime + _round * founderLockance[msg.sender].period);
        require(founderLockance[msg.sender].remainRound > 0);
        require(founderLockance[msg.sender].totalRound - founderLockance[msg.sender].remainRound < _round);
        uint256 _amount = founderLockance[msg.sender].amount;
        balances[msg.sender] += _amount;
        founderLockance[msg.sender].remainRound --;
        FounderUnlock(msg.sender, _amount);
    }
    
     
    function openIco () onlyOwner{
        icoOpen = true;
      }
     
    function closeIco () onlyOwner inIco{
        icoOpen = false;
      }

     
    function weAreClosed () onlyOwner{
        bountyToken += publicToken;
        publicToken = 0;
    }
     
    function changeRate (uint256 _rate) onlyOwner{
        require(_rate >= 5000 && _rate <= 8000);     
        exchangeRate = _rate;
    }
    
    
     
    function addMember (address _member, uint256 _value) onlyOwner{
        require(_value <= reserveMember);
        reserveMember -= _value;
        balances[contract_owner] += _value;
        transfer(_member, _value);
        _initialAmount += _value;
    }
     
    function addFounder (address _founder, uint256 _value) onlyOwner{
        require(_value <= reservedFounder);
        reservedFounder -= _value;
        balances[contract_owner] += _value;
        transfer(_founder, _value);
        _initialAmount += _value;
    }
     
    function obtainBounty (address _receiver, uint256 _value) onlyOwner{
        require(_value <= bountyToken);
        balances[_receiver] += _value;
        _initialAmount += _value;
        bountyToken -= _value;
    }
    
    
     
    function withdraw() onlyOwner{
        contract_owner.transfer(this.balance);
      }
     
    function () payable inIco{
        uint256 tokenChange = (msg.value * exchangeRate).div(10**18);
        require(tokenChange <= publicToken);
        balances[msg.sender] += tokenChange;
        _initialAmount += tokenChange;
        publicToken = publicToken.sub(tokenChange);
      }
}