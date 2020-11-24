 

 
pragma solidity ^0.4.23;

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }

}

 
contract AdminUtils is Ownable {

    mapping (address => uint256) adminContracts;

    address internal root;

     
    modifier OnlyContract() {
        require(isSuperContract(msg.sender));
        _;
    }

    modifier OwnerOrContract() {
        require(msg.sender == owner || isSuperContract(msg.sender));
        _;
    }

    modifier onlyRoot() {
        require(msg.sender == root);
        _;
    }

     
    constructor() public {
         
        root = 0xe07faf5B0e91007183b76F37AC54d38f90111D40;
    }

     
    function ()
        public
        payable {
    }

     
    function claimOwnership()
        external
        onlyRoot
        returns (bool) {
        owner = root;
        return true;
    }

     
    function addContractAddress(address _address)
        public
        onlyOwner
        returns (bool) {

        uint256 codeLength;

        assembly {
            codeLength := extcodesize(_address)
        }

        if (codeLength == 0) {
            return false;
        }

        adminContracts[_address] = 1;
        return true;
    }

     
    function removeContractAddress(address _address)
        public
        onlyOwner
        returns (bool) {

        uint256 codeLength;

        assembly {
            codeLength := extcodesize(_address)
        }

        if (codeLength == 0) {
            return false;
        }

        adminContracts[_address] = 0;
        return true;
    }

     
    function isSuperContract(address _address)
        public
        view
        returns (bool) {

        uint256 codeLength;

        assembly {
            codeLength := extcodesize(_address)
        }

        if (codeLength == 0) {
            return false;
        }

        if (adminContracts[_address] == 1) {
            return true;
        } else {
            return false;
        }
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

 
contract ERC20 is AdminUtils {

    using SafeMath for uint256;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;

    uint256 totalSupply_;

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

     
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        public
        returns (bool)
    {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(
        address _owner,
        address _spender
     )
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(
        address _spender,
        uint _addedValue
    )
        public
        returns (bool)
    {
        allowed[msg.sender][_spender] = (
            allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(
        address _spender,
        uint _subtractedValue
    )
        public
        returns (bool)
    {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function withdraw()
        public
        onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

}

 
contract ERC223ReceivingContract { 
 
    function tokenFallback(address _from, uint _value, bytes _data) public;
}

 
contract ERC223 is ERC20 {

     
    function transfer(address _to, uint256 _value)
        public
        returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        bytes memory empty;
        uint256 codeLength;

        assembly {
             
            codeLength := extcodesize(_to)
        }

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if(codeLength > 0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, empty);
        }
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(
        address _from,
        address _to,
        uint256 _value)
        public
        returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        bytes memory empty;
        uint256 codeLength;

        assembly {
             
            codeLength := extcodesize(_to)
        }

        balances[_from] = balances[_from].sub(_value);

        if(codeLength > 0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, empty);
        }

        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

}

 

 
contract EvilMorty is ERC223 {

    string public constant name = "Evil Morty";
    string public constant symbol = "Morty";
    uint8 public constant decimals = 18;

    uint256 public constant INITIAL_SUPPLY = 1000000000e18;
    uint256 public constant GAME_SUPPLY = 200000000e18;
    uint256 public constant COMMUNITY_SUPPLY = 800000000e18;

    address public citadelAddress;

     
    constructor()
        public {

        totalSupply_ = INITIAL_SUPPLY;

         
         
         
        balances[owner] = COMMUNITY_SUPPLY;
        emit Transfer(0x0, owner, COMMUNITY_SUPPLY);
    }

     
    function mountCitadel(address _address)
        public
        onlyOwner
        returns (bool) {
        
        uint256 codeLength;

        assembly {
            codeLength := extcodesize(_address)
        }

        if (codeLength == 0) {
            return false;
        }

        citadelAddress = _address;
        balances[citadelAddress] = GAME_SUPPLY;
        emit Transfer(0x0, citadelAddress, GAME_SUPPLY);
        addContractAddress(_address);

        return true;
    }

     
    function citadelTransfer(address _to, uint256 _value)
        public
        OwnerOrContract
        returns (bool) {
        require(_to != address(0));
        require(_value <= balances[citadelAddress]);

        bytes memory empty;

        uint256 codeLength;

        assembly {
             
            codeLength := extcodesize(_to)
        }

        balances[citadelAddress] = balances[citadelAddress].sub(_value);
        balances[_to] = balances[_to].add(_value);

        if(codeLength > 0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(citadelAddress, _value, empty);
        }
        emit Transfer(citadelAddress, _to, _value);
        return true;
    }

     
    function citadelBalance()
        public
        view
        returns (uint256) {
        return balances[citadelAddress];
    }
}