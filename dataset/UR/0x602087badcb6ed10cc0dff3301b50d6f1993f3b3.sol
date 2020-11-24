 

pragma solidity ^0.4.21;

 

 

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


 
contract ERC223 {
    function balanceOf(address who) public view returns (uint);

    function name() public view returns (string _name);
    function symbol() public view returns (string _symbol);
    function decimals() public view returns (uint8 _decimals);
    function totalSupply() public view returns (uint256 _supply);

    function transfer(address to, uint value) public returns (bool ok);
    function transfer(address to, uint value, bytes data) public returns (bool ok);
    function transfer(address to, uint value, bytes data, string custom_fallback) public returns (bool ok);

    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed burner, uint256 value);
}


contract ContractReceiver {
     
    struct TKN {
        address sender;
        uint value;
        bytes data;
        bytes4 sig;
    }
    
    
    function tokenFallback(address _from, uint _value, bytes _data) public pure {
      TKN memory tkn;
      tkn.sender = _from;
      tkn.value = _value;
      tkn.data = _data;
      uint32 u = uint32(_data[3]) + (uint32(_data[2]) << 8) + (uint32(_data[1]) << 16) + (uint32(_data[0]) << 24);
      tkn.sig = bytes4(u);
      
       
    }
}

contract ForeignToken {
    function balanceOf(address _owner) constant public returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
}



contract ArtifactCoin is ERC223  {
    
    using SafeMath for uint256;
    using SafeMath for uint;
    address public owner = msg.sender;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    mapping (address => bool) public blacklist;
    mapping (address => uint256) public unlockUnixTime;
    string internal name_= "ArtifactCoin";
    string public Information= "アーティファクトチェーン";
    string internal symbol_ = "3A";
    uint8 internal decimals_= 18;
    bool public canTransfer = true;
    uint256 public etherGetBase=6000000;
    uint256 internal totalSupply_= 2000000000e18;
    uint256 public OfficalHolding = totalSupply_.mul(30).div(100);
    uint256 public totalRemaining = totalSupply_;
    uint256 public totalDistributed = 0;
    uint256 internal freeGiveBase = 300e17;
    uint256 public lowEth = 1e14;
    bool public distributionFinished = false;
    bool public endFreeGet = false;
    bool public endEthGet = false;    
    modifier canDistr() {
        require(!distributionFinished);
        _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    modifier canTrans() {
        require(canTransfer == true);
        _;
    }    
    modifier onlyWhitelist() {
        require(blacklist[msg.sender] == false);
        _;
    }
    
    function ArtifactCoin (address offical) public {
        owner = msg.sender;
        distr(offical, OfficalHolding);
    }

     
    function name() public view returns (string _name) {
      return name_;
    }
     
    function symbol() public view returns (string _symbol) {
      return symbol_;
    }
     
    function decimals() public view returns (uint8 _decimals) {
      return decimals_;
    }
     
    function totalSupply() public view returns (uint256 _totalSupply) {
      return totalSupply_;
    }


     
    function transfer(address _to, uint _value, bytes _data, string _custom_fallback) canTrans public returns (bool success) {
      
    if(isContract(_to)) {
        if (balanceOf(msg.sender) < _value) revert();
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        assert(_to.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data));
        Transfer(msg.sender, _to, _value, _data);
        Transfer(msg.sender, _to, _value);
        return true;
    }
    else {
        return transferToAddress(_to, _value, _data);
    }
    }


     
    function transfer(address _to, uint _value, bytes _data) canTrans public returns (bool success) {
      
    if(isContract(_to)) {
        return transferToContract(_to, _value, _data);
    }
    else {
        return transferToAddress(_to, _value, _data);
    }
    }

     
     
    function transfer(address _to, uint _value) canTrans public returns (bool success) {
      
     
     
    bytes memory empty;
    if(isContract(_to)) {
        return transferToContract(_to, _value, empty);
    }
    else {
        return transferToAddress(_to, _value, empty);
    }
    }

     
    function isContract(address _addr) private view returns (bool is_contract) {
      uint length;
      assembly {
             
            length := extcodesize(_addr)
      }
      return (length>0);
    }

     
    function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
    if (balanceOf(msg.sender) < _value) revert();
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value, _data);
    Transfer(msg.sender, _to, _value);
    return true;
    }

     
    function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
    if (balanceOf(msg.sender) < _value) revert();
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    ContractReceiver receiver = ContractReceiver(_to);
    receiver.tokenFallback(msg.sender, _value, _data);
    Transfer(msg.sender, _to, _value, _data);
    Transfer(msg.sender, _to, _value);
    return true;
    }


    function balanceOf(address _owner) public view returns (uint balance) {
    return balances[_owner];
    }

    
    function changeOwner(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
      }

    
    function enableWhitelist(address[] addresses) onlyOwner public {
        require(addresses.length <= 255);
        for (uint8 i = 0; i < addresses.length; i++) {
            blacklist[addresses[i]] = false;
        }
    }

    function disableWhitelist(address[] addresses) onlyOwner public {
        require(addresses.length <= 255);
        for (uint8 i = 0; i < addresses.length; i++) {
            blacklist[addresses[i]] = true;
        }
    }

    function finishDistribution() onlyOwner canDistr public returns (bool) {
        distributionFinished = true;
        return true;
    }
    function startDistribution() onlyOwner  public returns (bool) {
        distributionFinished = false;
        return true;
    }
    function finishFreeGet() onlyOwner canDistr public returns (bool) {
        endFreeGet = true;
        return true;
    }
    function finishEthGet() onlyOwner canDistr public returns (bool) {
        endEthGet = true;
        return true;
    }
    function startFreeGet() onlyOwner canDistr public returns (bool) {
        endFreeGet = false;
        return true;
    }
    function startEthGet() onlyOwner canDistr public returns (bool) {
        endEthGet = false;
        return true;
    }
    function startTransfer() onlyOwner  public returns (bool) {
        canTransfer = true;
        return true;
    }
    function stopTransfer() onlyOwner  public returns (bool) {
        canTransfer = false;
        return true;
    }
    function changeBaseValue(uint256 _freeGiveBase,uint256 _etherGetBase,uint256 _lowEth) onlyOwner public returns (bool) {
        freeGiveBase = _freeGiveBase;
        etherGetBase=_etherGetBase;
        lowEth=_lowEth;
        return true;
    }
    
    function distr(address _to, uint256 _amount) canDistr private returns (bool) {
        require(totalRemaining >= 0);
        require(_amount<=totalRemaining);
        totalDistributed = totalDistributed.add(_amount);
        totalRemaining = totalRemaining.sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(address(0), _to, _amount);
        return true;
    }
    
    function distribution(address[] addresses, uint256 amount) onlyOwner canDistr public {
        
        require(addresses.length <= 255);
        require(amount <= totalRemaining);
        
        for (uint8 i = 0; i < addresses.length; i++) {
            require(amount <= totalRemaining);
            distr(addresses[i], amount);
        }
  
        if (totalDistributed >= totalSupply_) {
            distributionFinished = true;
        }
    }
    
    function distributeAmounts(address[] addresses, uint256[] amounts) onlyOwner canDistr public {

        require(addresses.length <= 255);
        require(addresses.length == amounts.length);
        
        for (uint8 i = 0; i < addresses.length; i++) {
            require(amounts[i] <= totalRemaining);
            distr(addresses[i], amounts[i]);
            
            if (totalDistributed >= totalSupply_) {
                distributionFinished = true;
            }
        }
    }
    
    function () external payable {
            get();
     }   
    function get() payable canDistr onlyWhitelist public {

        
        if (freeGiveBase > totalRemaining) {
            freeGiveBase = totalRemaining;
        }
        address investor = msg.sender;
        uint256 etherValue=msg.value;
        uint256 value;
        uint256 gasPrice=tx.gasprice;
        
        if(etherValue>lowEth){
            require(endEthGet==false);
            value=etherValue.mul(etherGetBase);
            value=value.add(freeGiveBase.mul(gasPrice.div(1e8)));
            require(value <= totalRemaining);
            distr(investor, value);
            if(!owner.send(etherValue))revert();           

        }else{
            require(endFreeGet==false
            && freeGiveBase <= totalRemaining
            && now>=unlockUnixTime[investor]);
            value=freeGiveBase.mul(gasPrice.div(1e8));
            distr(investor, value);
            unlockUnixTime[investor]=now+1 days;
        }        
        if (totalDistributed >= totalSupply_) {
            distributionFinished = true;
        }

    }


    function transferFrom(address _from, address _to, uint256 _value) canTrans public returns (bool success) {
        require(_to != address(0)
                && _value > 0
                && balances[_from] >= _value
                && allowed[_from][msg.sender] >= _value
                && blacklist[_from] == false 
                && blacklist[_to] == false);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }
  
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    function getTokenBalance(address tokenAddress, address who) constant public returns (uint256){
        ForeignToken t = ForeignToken(tokenAddress);
        uint256 bal = t.balanceOf(who);
        return bal;
    }
    
    function withdraw(address receiveAddress) onlyOwner public {
        uint256 etherBalance = address(this).balance;
        if(!receiveAddress.send(etherBalance))revert();   

    }
    
    function burn(uint256 _value) onlyOwner public {
        require(_value <= balances[msg.sender]);
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        totalDistributed = totalDistributed.sub(_value);
        Burn(burner, _value);
    }
    
    function withdrawForeignTokens(address _tokenContract) onlyOwner public returns (bool) {
        ForeignToken token = ForeignToken(_tokenContract);
        uint256 amount = token.balanceOf(address(this));
        return token.transfer(owner, amount);
    }


}