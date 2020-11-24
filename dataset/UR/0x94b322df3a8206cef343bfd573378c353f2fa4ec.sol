 

pragma solidity ^0.4.18;

 

 
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

 

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

 

 
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

 
contract ERC223 {
    uint public totalSupply;

     
    function balanceOf(address who) public view returns (uint);
    function totalSupply() public view returns (uint256 _supply);
    function transfer(address to, uint value) public returns (bool ok);
    function transfer(address to, uint value, bytes data) public returns (bool ok);
    function transfer(address to, uint value, bytes data, string customFallback) public returns (bool ok);
    event Transfer(address indexed from, address indexed to, uint value, bytes data);

     
    function name() public view returns (string _name);
    function symbol() public view returns (string _symbol);
    function decimals() public view returns (uint8 _decimals);

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
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


 
contract MangachainToken is ERC223, Pausable {
    using SafeMath for uint256;

    string public name = "Mangachain Token";
    string public symbol = "MCT";
    uint8 public decimals = 8;
    uint256 public totalSupply = 5e10 * 1e8;
    uint256 public distributeAmount = 0;
    bool public mintingFinished = false;
    address public depositAddress;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping (address => uint256)) public allowance;
    mapping (address => uint256) public unlockUnixTime;

    event LockedFunds(address indexed target, uint256 locked);
    event Burn(address indexed from, uint256 amount);
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

     
    function MangachainToken(address _team, address _development, address _marketing, address _release, address _deposit) public {
      owner = _team;
      depositAddress = _deposit;

      balanceOf[_team] = totalSupply.mul(15).div(100);
      balanceOf[_development] = totalSupply.mul(15).div(100);
      balanceOf[_marketing] = totalSupply.mul(30).div(100);
      balanceOf[_release] = totalSupply.mul(40).div(100);
    }


    function name() public view returns (string _name) {
        return name;
    }

    function symbol() public view returns (string _symbol) {
        return symbol;
    }

    function decimals() public view returns (uint8 _decimals) {
        return decimals;
    }

    function totalSupply() public view returns (uint256 _totalSupply) {
        return totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balanceOf[_owner];
    }

     
    function lockupAccounts(address[] targets, uint[] unixTimes) onlyOwner public {
        require(targets.length > 0
                && targets.length == unixTimes.length);

        for(uint i = 0; i < targets.length; i++){
            require(unlockUnixTime[targets[i]] < unixTimes[i]);
            unlockUnixTime[targets[i]] = unixTimes[i];
            LockedFunds(targets[i], unixTimes[i]);
        }
    }


     
    function transfer(address _to, uint _value, bytes _data, string _custom_fallback) whenNotPaused public returns (bool success) {
        require(_value > 0
                && now > unlockUnixTime[msg.sender]
                && now > unlockUnixTime[_to]);

        if (isContract(_to)) {
            require(balanceOf[msg.sender] >= _value);
            balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
            balanceOf[_to] = balanceOf[_to].add(_value);
            assert(_to.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data));
            Transfer(msg.sender, _to, _value, _data);
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return transferToAddress(_to, _value, _data);
        }
    }

    function transfer(address _to, uint _value, bytes _data) whenNotPaused public returns (bool success) {
        require(_value > 0
                && now > unlockUnixTime[msg.sender]
                && now > unlockUnixTime[_to]);

        if (isContract(_to)) {
            return transferToContract(_to, _value, _data);
        } else {
            return transferToAddress(_to, _value, _data);
        }
    }

     
    function transfer(address _to, uint _value) whenNotPaused public returns (bool success) {
        require(_value > 0
                && now > unlockUnixTime[msg.sender]
                && now > unlockUnixTime[_to]);

        bytes memory empty;
        if (isContract(_to)) {
            return transferToContract(_to, _value, empty);
        } else {
            return transferToAddress(_to, _value, empty);
        }
    }

     
    function isContract(address _addr) private view returns (bool is_contract) {
        uint length;
        assembly {
             
            length := extcodesize(_addr)
        }
        return (length > 0);
    }

     
    function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        Transfer(msg.sender, _to, _value, _data);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        Transfer(msg.sender, _to, _value, _data);
        Transfer(msg.sender, _to, _value);
        return true;
    }



     
    function transferFrom(address _from, address _to, uint256 _value) whenNotPaused public returns (bool success) {
        require(_to != address(0)
                && _value > 0
                && balanceOf[_from] >= _value
                && allowance[_from][msg.sender] >= _value
                && now > unlockUnixTime[_from]
                && now > unlockUnixTime[_to]);

        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) whenNotPaused public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowance[_owner][_spender];
    }

    function distributeTokens(address[] addresses, uint[] amounts) whenNotPaused public returns (bool) {
        require(addresses.length > 0
                && addresses.length == amounts.length
                && now > unlockUnixTime[msg.sender]);

        uint256 totalAmount = 0;

        for(uint i = 0; i < addresses.length; i++){
            require(amounts[i] > 0
                    && addresses[i] != 0x0
                    && now > unlockUnixTime[addresses[i]]);

            amounts[i] = amounts[i].mul(1e8);
            totalAmount = totalAmount.add(amounts[i]);
        }
        require(balanceOf[msg.sender] >= totalAmount);

        for (i = 0; i < addresses.length; i++) {
            balanceOf[addresses[i]] = balanceOf[addresses[i]].add(amounts[i]);
            Transfer(msg.sender, addresses[i], amounts[i]);
        }
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(totalAmount);
        return true;
    }

     
    function collectTokens(address[] _targets) onlyOwner whenNotPaused public returns (bool) {
      require(_targets.length > 0);

      uint256 totalAmount = 0;

      for (uint i = 0; i < _targets.length; i++) {
        require(_targets[i] != 0x0 && now > unlockUnixTime[_targets[i]]);

        totalAmount = totalAmount.add(balanceOf[_targets[i]]);
        Transfer(_targets[i], depositAddress, balanceOf[_targets[i]]);
        balanceOf[_targets[i]] = 0;
      }

      balanceOf[depositAddress] = balanceOf[depositAddress].add(totalAmount);
      return true;
    }

    function setDepositAddress(address _addr) onlyOwner whenNotPaused public {
      require(_addr != 0x0 && now > unlockUnixTime[_addr]);
      depositAddress = _addr;
    }

     
    function burn(address _from, uint256 _unitAmount) onlyOwner public {
        require(_unitAmount > 0
                && balanceOf[_from] >= _unitAmount);

        balanceOf[_from] = balanceOf[_from].sub(_unitAmount);
        totalSupply = totalSupply.sub(_unitAmount);
        Burn(_from, _unitAmount);
    }


    modifier canMint() {
        require(!mintingFinished);
        _;
    }

     
    function mint(address _to, uint256 _unitAmount) onlyOwner canMint public returns (bool) {
        require(_unitAmount > 0);

        totalSupply = totalSupply.add(_unitAmount);
        balanceOf[_to] = balanceOf[_to].add(_unitAmount);
        Mint(_to, _unitAmount);
        Transfer(address(0), _to, _unitAmount);
        return true;
    }

     
    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }

    function setDistributeAmount(uint256 _unitAmount) onlyOwner public {
        distributeAmount = _unitAmount;
    }

     
    function autoDistribute() payable public {
        require(distributeAmount > 0
                && balanceOf[depositAddress] >= distributeAmount
                && now > unlockUnixTime[msg.sender]);
        if(msg.value > 0) depositAddress.transfer(msg.value);

        balanceOf[depositAddress] = balanceOf[depositAddress].sub(distributeAmount);
        balanceOf[msg.sender] = balanceOf[msg.sender].add(distributeAmount);
        Transfer(depositAddress, msg.sender, distributeAmount);
    }

     
    function() payable public {
        autoDistribute();
     }
}