 

pragma solidity ^0.4.24;

contract ERC20 {
  function totalSupply() public view returns (uint256);

  function balanceOf(address _who) public view returns (uint256);

  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transfer(address _to, uint256 _value) public returns (bool);

  function approve(address _spender, uint256 _value)
    public returns (bool);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract Ownable {

   
  address public owner;

   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0));
    emit OwnerChanged(owner, _newOwner);
    owner = _newOwner;
  }

  event OwnerChanged(address indexed previousOwner,address indexed newOwner);

}

contract Pausable is Ownable {

    bool public paused = false;

     
    modifier whenNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

     
    modifier whenPaused() {
        require(paused);
        _;
    }

     
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

     
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }

    event Pause();
    event Unpause();
}

library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

contract StandardToken is ERC20 {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  mapping (address => mapping (address => uint256)) internal allowed;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
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

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function increaseApproval(
    address _spender,
    uint256 _addedValue
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
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract PausableToken is StandardToken, Pausable {

  function transfer(
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transfer(_to, _value);
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(
    address _spender,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.approve(_spender, _value);
  }

  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

contract ElpisToken is PausableToken {

     
    string public constant name = "Elpis AI Trading Token";
    
     
    string public constant symbol = "ELP";

     
    uint8 public constant decimals = 18;
    
     
    uint256 public deploymentBlock;

    constructor() public {
        deploymentBlock = block.number;
        totalSupply_ = 250000000 ether;
        balances[msg.sender] = totalSupply_;
        
         
        transfer(0x6467704b5CD5a5A380656886AE0284133825D378, 7000000000000000000000000);
        transfer(0x7EF7F9104867454f0E3cd8B4aE99045a01f605c0, 1000000000000000000000000);

         
        transfer(0x1499493fd2fdb2c6d536569322fe37f5da24a5c9, 4672955120000000000000000);
        transfer(0x22a5c82364faa085394b6e82d8d39643d0ad38e7, 2500000000000000000000000);
        transfer(0xdc64259785a9dbae1b40fee4dfe2055af4fefd6b, 2000000000000000000000000);
        transfer(0xbd14c21b0ed5fefee65d9c0609136fff8aafb1e8, 1500000000000000000000000);
        transfer(0x4aca633f98559bb7e6025c629e1789537b9ee72f, 1000000000000000000000000);
        transfer(0x4aeac209d18151f79ff5dc320619a554872b099d, 1000000000000000000000000);
        transfer(0x9d3b6f11c9f17bf98e1bc8618a17bb1e9928e1c1, 1000000000000000000000000);
        transfer(0xffdfb7ef8e05b02a6bc024c15ce5e89f0561a6f7, 646900270000000000000000);
        transfer(0x6d91062c251eb5042a71312e704c297fb924409c, 379937110000000000000000);
        transfer(0x5182531e3ebeb35af19e00fa5de03a12d46eba72, 379200360000000000000000);
        transfer(0x8b751c5d881ab355a0b5109ea1a1a7e0a7c0ea36, 125000000000000000000000);
        transfer(0x6a877aa35ef434186985d07270ba50685d1b7ada, 60000000000000000000000);
        transfer(0x9ecedc01e9fde532a5f30f398cbc0261e88136a1, 28264000000000000000000);
        transfer(0xd24400ae8bfebb18ca49be86258a3c749cf46853, 22641509433000000000000);
        transfer(0x964fcf14cbbd03b89caab136050cc02e6949d5e7, 15094339622000000000000);
        transfer(0xdc8ce4f0278968f48c059461abbc59c27c08b6f0, 10062893081000000000000);
        transfer(0x2c06c71e718ca02435804b0ce313a1333cb06d02, 9811320754000000000000);
        transfer(0x9cca8e43a9a37c3969bfd0d3e0cdf60e732c0cee, 8050314464000000000000);
        transfer(0xa48f71410d01ec4ca59c36af3a2e2602c28d8fc2, 7547169811000000000000);
        transfer(0xeb5e9a1469da277b056a4bc250af4489eda36621, 5031446540000000000000);
        transfer(0xbb5c14e2a821c0bada4ae7217d23c919472f7f77, 3773584905000000000000);
        transfer(0x46b5c439228015e2596c7b2da8e81a705990c6ac, 3773584905000000000000);
        transfer(0x3e7a3fb0976556aaf12484de68350ac3b6ae4c40, 2515723270000000000000);
        transfer(0xe14362f83a0625e57f1ca92d515c3c060d7d5659, 2264150943000000000000);
        transfer(0x795df9a9699b399ffc512732d2c797c781c22bc7, 1509433962000000000000);
        transfer(0xaca9fd46bfa5e903a75fb604f977792bd349a1af, 1396226415000000000000);
        transfer(0xe2cdffd7b906cdd7ae74d8eb8553328a66d12b84, 1368887886000000000000);
        transfer(0xee76d34d75ee0a72540abca5b26270b975f6adb6, 1320754716000000000000);
        transfer(0xc44aa2d68d51fa5195b3d03af14a3706feeb29fc, 1320754716000000000000);
        transfer(0xe694d8dd4b01bb12cb44568ebed792bd45a3f2cf, 1257861635000000000000);
        transfer(0x9484e40deff4c6b4a475fe7625d3c70c71f54db7, 1207547169000000000000);
        transfer(0x15ae5afd84c15f740a28a45fe166e161e3ed9251, 1132075471000000000000);
        transfer(0x7fd9138acbcf9b1600eea70befe87729cc30968b, 1006289308000000000000);
        transfer(0xfd3c389d724a230b4d086a77c83013ef6b4afdf1, 766037735000000000000);
        transfer(0x774c988ec49df627093b6755c3baebb0d9a9d0b3, 758650475000000000000);
        transfer(0x7a0702d58d6a4b6f06a9d275dc027555148e81c7, 754716981000000000000);
        transfer(0x4b1b467a6a80af7ebc53051015e089b20588f1e7, 566037735000000000000);
        transfer(0x0f6e5559ba758638d0931528967a54b9b5182b93, 566037735000000000000);
        transfer(0xc1ec7ea396923d1a866a4f3798a87d1a92b9e37a, 556345720000000000000);
        transfer(0x64bea49dd8d3a328a4aa4c739d776b0bfdda6128, 503144654000000000000);
        transfer(0x472745526b7f72f7a9eb117e738f309d2abcc1a2, 503144654000000000000);
        transfer(0xe3f68a6b6b39534a975eb9605dd71c8e36989e52, 490566037000000000000);
        transfer(0x0caef953d12a24680c821d6e292a74634351d5a6, 452830188000000000000);
        transfer(0x3f5d8a83b470b9d51b9c5a9ac1928e4e77a37842, 427942513000000000000);
        transfer(0xfbb1b73c4f0bda4f67dca266ce6ef42f520fbb98, 422382641000000000000);
        transfer(0x0b9fe4475e6a5ecbfb1fefc56c4c28fe97064dc1, 415094339000000000000);
        transfer(0x83658d1d001092cabf33502cd1c66c91c16a18a6, 377358490000000000000);
        transfer(0x236bea162cc2115b20309c632619ac876682becc, 94339622000000000000);
        transfer(0xdfb2b0210081bd17bc30bd163c415ba8a0f3e316, 60314465000000000000);
        transfer(0x92df16e27d3147cf05e190e633bf934e654eec86, 50314465000000000000);
        transfer(0x6dd451c3f06a24da0b37d90e709f0e9f08987673, 40314465000000000000);
        transfer(0x550c6de28d89d876ca5b45e3b87e5ae4374aa770, 1000000000000000000);
    }

     
    function() external payable {
        revert();
    }

     
    function claimTokens(address _token) public onlyOwner {
        if (_token == address(0)) {
            owner.transfer(address(this).balance);
            return;
        }

        ERC20 token = ERC20(_token);
        uint balance = token.balanceOf(address(this));
        token.transfer(owner, balance);
        emit ClaimedTokens(_token, owner, balance);
    }

     
    function burn(address _target, uint256 _value) public onlyOwner {
        require(_value <= balances[_target]);
        balances[_target] = balances[_target].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(_target, _value);
        emit Transfer(_target, address(0), _value);
    }

     
    event Burn(address indexed burner, uint256 value);

     
    event ClaimedTokens(address indexed token, address indexed owner, uint256 amount);

}