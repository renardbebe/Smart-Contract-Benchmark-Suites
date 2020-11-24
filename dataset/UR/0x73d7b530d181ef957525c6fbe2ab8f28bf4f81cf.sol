 

pragma solidity ^0.4.23;

 

 
contract ERC20Interface {
   
  event Transfer(address indexed _from, address indexed _to, uint256 _value);

   
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

   
  function totalSupply() public view returns (uint256 _supply);

   
  function balanceOf(address _owner) public view returns (uint256 _balance);

   
  function transfer(address _to, uint256 _value) public returns (bool _success);

   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool _success);

   
  function approve(address _spender, uint256 _value) public returns (bool _success);

   
  function allowance(address _owner, address _spender) public view returns (uint256 _remaining);
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

 

 
contract ERC20 is ERC20Interface {
  using SafeMath for uint256;

  uint256 internal _totalSupply;
  mapping (address => uint256) internal _balance;
  mapping (address => mapping (address => uint256)) internal _allowed;


   
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return _balance[_owner];
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    _balance[msg.sender] = _balance[msg.sender].sub(_value);
    _balance[_to] = _balance[_to].add(_value);

    emit Transfer(msg.sender, _to, _value);

    return true;
  }

   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    _balance[_from] = _balance[_from].sub(_value);
    _balance[_to] = _balance[_to].add(_value);
    _allowed[_from][msg.sender] = _allowed[_from][msg.sender].sub(_value);

    emit Transfer(_from, _to, _value);

    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    _allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return _allowed[_owner][_spender];
  }
}

 

 
contract ERC20Burnable is ERC20 {
  event Burn(address indexed burner, uint256 value);

  function burn(uint256 _value) public returns (bool) {
    _balance[msg.sender] = _balance[msg.sender].sub(_value);
    _totalSupply = _totalSupply.sub(_value);

    emit Transfer(msg.sender, address(0), _value);
    emit Burn(msg.sender, _value);

    return true;
  }

  function burnFrom(address _from, uint256 _value) public returns (bool) {
    _balance[_from] = _balance[_from].sub(_value);
    _totalSupply = _totalSupply.sub(_value);
    _allowed[_from][msg.sender] = _allowed[_from][msg.sender].sub(_value);

    emit Transfer(_from, address(0), _value);
    emit Burn(_from, _value);

    return true;
  }
}

 

 
contract ERC20DetailedInterface is ERC20Interface {
   
  function name() public view returns (string _name);

   
  function symbol() public view returns (string _symbol);

   
  function decimals() public view returns (uint8 _decimals);
}

 

interface ERC20RecipientInterface {
  function receiveApproval(address _from, uint256 _value, address _erc20Address, bytes _data) external;
}

 

 
contract ERC20Extended is ERC20 {
   
  function approveAndCall(address _spender, uint256 _value, bytes _data) public returns (bool) {
    require(approve(_spender, _value));
    ERC20RecipientInterface(_spender).receiveApproval(msg.sender, _value, this, _data);
    return true;
  }
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

 

 
contract ERC20Mintable is ERC20, Ownable {
  bool public mintingFinished = false;

  event Mint(address indexed to, uint256 value);
  event MintFinished();

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  function mint(address _to, uint256 _value) onlyOwner canMint public returns (bool) {
    _balance[_to] = _balance[_to].add(_value);
    _totalSupply = _totalSupply.add(_value);

    emit Mint(_to, _value);
    emit Transfer(address(0), _to, _value);

    return true;
  }

  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

 

 
contract AxieOriginCoin is ERC20DetailedInterface, ERC20Extended, ERC20Mintable, ERC20Burnable {
  uint256 constant public NUM_COIN_PER_AXIE = 5;
  uint256 constant public NUM_RESERVED_AXIE = 427;
  uint256 constant public NUM_RESERVED_COIN = NUM_RESERVED_AXIE * NUM_COIN_PER_AXIE;

  constructor() public {
     
    mint(msg.sender, NUM_RESERVED_COIN);

     
    _allocateUnspentRefTokens();

     
    finishMinting();
  }

   
  function name() public view returns (string) {
    return "Axie Origin Coin";
  }

   
  function symbol() public view returns (string) {
    return "AOC";
  }

   
  function decimals() public view returns (uint8) {
    return 0;
  }

  function _allocateUnspentRefTokens() private {
     
    mint(0x052731748979e182fdf9Bf849C6df54f9f196645, 3);
    mint(0x1878B18693fc273DE9FD833B83f9679785c01aB2, 1);
    mint(0x1E3934EA7E416F4E2BC5F7d55aE9783da0061475, 1);
    mint(0x32451d81EB31411B2CA4e70F3d87B3DEACCEA2d2, 3);
    mint(0x494952f01a30547d269aaF147e6226f940f5B041, 8);
     
    mint(0x5BD73bB4e2A9f81922dbE7F4b321cfAE208BE2E6, 1);
    mint(0x6564A5639e17e186f749e493Af98a51fd3092048, 12);
    mint(0x696A567271BBDAC6f435CAb9D69e56cD115B76eB, 1);
    mint(0x70580eA14d98a53fd59376dC7e959F4a6129bB9b, 2);
    mint(0x75f732C1b1D0bBdA60f4B49EF0B36EB6e8AD6531, 1);
     
    mint(0x84418eD93d141CFE7471dED46747D003117eCaD5, 2);
    mint(0x9455A90Cbf43D331Dd76a2d07192431370f64384, 2);
    mint(0x95fd3579c73Ea675C89415285355C4795118B345, 1);
    mint(0xa3346F3Af6A3AE749aCA18d7968A03811d15d733, 1);
    mint(0xA586A3B8939e9C0DC72D88166F6F6bb7558EeDCe, 1);
     
    mint(0xAb01D4895b802c38Eee7553bb52A4160CFca2878, 1);
    mint(0xd6E8D52Be82550B230176b6E9bA49BC3fAF43E4a, 1);
    mint(0xEAB0c22D927d15391dd0CfbE89a3b59F6e814551, 3);
    mint(0x03300279d711b8dEb1353DD9719eFf81Ea1b6bEd, 3);
    mint(0x03b4A1fdeCeC66338071180a7F2f2D518CFf224A, 4);
     
    mint(0x0537544De3935408246EE2Ad09949D046F92574D, 4);
    mint(0x0E26169270D92Ff3649461B55CA51C99703dE59e, 1);
    mint(0x16Ea1F673E01419BA9aF51365b88138Ac492489a, 1);
    mint(0x28d02f67316123Dc0293849a0D254AD86b379b34, 2);
    mint(0x38A6022FECb675a53F31CDaB3457456DD6e5911c, 2);
     
    mint(0x4260E8206c58cD0530d9A5cff55B77D6165c7BCd, 1);
    mint(0x7E1DCf785f0353BF657c38Ab7865C1f184EFE208, 4);
    mint(0x7f328117b7de7579C6249258d084f75556E2699d, 1);
    mint(0x8a9d49a6e9D037843560091fC280B9Ff9819e462, 3);
    mint(0x8C5fC43ad00Cc53e11F61bEce329DDc5E3ea0929, 3);
     
    mint(0x8FF9679fc77B077cB5f8818B7B63022582b5d538, 1);
    mint(0x97bfc7fc1Ee5b25CfAF6075bac5d7EcA037AD694, 1);
    mint(0x993a64DB27a51D1E6C1AFF56Fb61Ba0Dac253acb, 2);
    mint(0xa6bCEc585F12CeFBa9709A080cE2EFD38f871024, 1);
    mint(0xaF6488744207273c79B896922e65651C61033787, 5);
     
    mint(0xB3C2a4ce7ce57A74371b7E3dAE8f3393229c2aaC, 3);
    mint(0xb4A90c06d5bC51D79D44e11336077b6F9ccD5683, 23);
    mint(0xB94c9e7D28e54cb37fA3B0D3FFeC24A8E4affA90, 3);
    mint(0xDe0D2e92e85B8B7828723Ee789ffA3Ba9FdCDb9c, 1);
    mint(0xe37Ba1117746473db68A807aE9E37a2088BDB20f, 1);
     
    mint(0x5eA1D56D0ddE1cA5B50c277275855F69edEfA169, 1);
    mint(0x6692DE2d4b3102ab922cB21157EeBCD9BDDDBb15, 4);
     
  }
}