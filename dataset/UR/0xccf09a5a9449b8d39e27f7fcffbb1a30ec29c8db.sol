 

pragma solidity ^0.4.13;

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract VeTokenizedAssetRegistry is Ownable {

     

    struct Asset {
        address addr;
        string meta;
    }

     

    mapping (string => Asset) assets;

     

    function VeTokenizedAssetRegistry()
        Ownable
    {
    }

     

    event AssetCreated(
        address indexed addr
    );

    event AssetRegistered(
        address indexed addr,
        string symbol,
        string name,
        string description,
        uint256 decimals
    );

    event MetaUpdated(string symbol, string meta);

     

    function create(
        string symbol,
        string name,
        string description,
        uint256 decimals,
        string source,
        string proof,
        uint256 totalSupply,
        string meta
    )
        public
        onlyOwner
        returns (address)
    {
        VeTokenizedAsset asset = new VeTokenizedAsset();
        asset.setup(
            symbol,
            name,
            description,
            decimals,
            source,
            proof,
            totalSupply
        );

        asset.transferOwnership(msg.sender);

        AssetCreated(asset);

        register(
            asset,
            symbol,
            name,
            description,
            decimals,
            meta
        );

        return asset;
    }

    function register(
        address addr,
        string symbol,
        string name,
        string description,
        uint256 decimals,
        string meta
    )
        public
        onlyOwner
    {
        assets[symbol].addr = addr;

        AssetRegistered(
            addr,
            symbol,
            name,
            description,
            decimals
        );

        updateMeta(symbol, meta);
    }

    function updateMeta(string symbol, string meta) public onlyOwner {
        assets[symbol].meta = meta;

        MetaUpdated(symbol, meta);
    }

    function getAsset(string symbol) public constant returns (address addr, string meta) {
        Asset storage asset = assets[symbol];
        addr = asset.addr;
        meta = asset.meta;
    }
}

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

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

     
     

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue)
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue)
    returns (bool success) {
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

contract VeTokenizedAsset is StandardToken, Ownable {

     

    using SafeMath for uint256;

     

    bool public configured;
    string public symbol;
    string public name;
    string public description;
    uint256 public decimals;
    string public source;
    string public proof;
    uint256 public totalSupply;

     

    function VeTokenizedAsset() {
         
    }

     

    event SourceChanged(string newSource, string newProof, uint256 newTotalSupply);
    event SupplyChanged(uint256 newTotalSupply);

     

    function setup(
        string _symbol,
        string _name,
        string _description,
        uint256 _decimals,
        string _source,
        string _proof,
        uint256 _totalSupply
    )
        public
        onlyOwner
    {
        require(!configured);
        require(bytes(_symbol).length > 0);
        require(bytes(_name).length > 0);
        require(_decimals > 0 && _decimals <= 32);

        symbol = _symbol;
        name = _name;
        description = _description;
        decimals = _decimals;
        source = _source;
        proof = _proof;
        totalSupply = _totalSupply;
        configured = true;

        balances[owner] = _totalSupply;

        SourceChanged(_source, _proof, _totalSupply);
    }

    function changeSource(string newSource, string newProof, uint256 newTotalSupply) onlyOwner {
        uint256 prevBalance = balances[owner];

        if (newTotalSupply < totalSupply) {
            uint256 decrease = totalSupply.sub(newTotalSupply);
            balances[owner] = prevBalance.sub(decrease);  
        } else if (newTotalSupply > totalSupply) {
            uint256 increase = newTotalSupply.sub(totalSupply);
            balances[owner] = prevBalance.add(increase);
        }

        source = newSource;
        proof = newProof;
        totalSupply = newTotalSupply;

        SourceChanged(newSource, newProof, newTotalSupply);
    }

    function mint(uint256 amount) public onlyOwner {
        require(amount > 0);

        totalSupply = totalSupply.add(amount);
        balances[owner] = balances[owner].add(amount);

        SupplyChanged(totalSupply);
    }

    function burn(uint256 amount) public onlyOwner {
        require(amount > 0);
        require(amount <= balances[owner]);

        totalSupply = totalSupply.sub(amount);
        balances[owner] = balances[owner].sub(amount);  

        SupplyChanged(totalSupply);
    }
}