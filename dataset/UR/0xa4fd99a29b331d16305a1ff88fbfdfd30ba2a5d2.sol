 

pragma solidity ^0.4.24;
 
 
 
 
 
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

contract PeepTokenConfig {
    string public constant NAME = "Devcon4PeepToken";
    string public constant SYMBOL = "PEEP";
    uint8 public constant DECIMALS = 0;
    uint public constant TOTALSUPPLY = 100;
}
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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

contract Salvageable is Ownable {
     
    function emergencyERC20Drain(ERC20 oddToken, uint amount) public onlyOwner {
        if (address(oddToken) == address(0)) {
            owner.transfer(amount);
            return;
        }
        oddToken.transfer(owner, amount);
    }
}
contract Devcon4PeepToken is StandardToken, PeepTokenConfig, Salvageable { 
    using SafeMath for uint;

    string  public name = NAME;
    string  public symbol = SYMBOL;
    uint8   public decimals = DECIMALS;
    uint    public numCardsPurchased;
    address public peepethAccount = 0xdD53530eAA9c7B47AD8f97a5BF1C797aB6f6cf28;
 
    event CardPurchased(address buyer, uint cardnumber, bytes32 data);

    constructor() public {
        issueCard(0x2a9623C8f0Afb3C61579130bA9285BdD122Dd003);
        issueCard(0xD64eed8e7250636Cb17f2314c81F9DF33a32A93D);
        issueCard(0x32D90824d2Bf1a668196939858269948E6a1afe0);
        issueCard(0xA0f0F8A9380Ce8925F5232EA6377A4C864B60BD1);
        issueCard(0x1a1146Fae0CA9F883827177cE0e3FDc17a3Dfc92);
        issueCard(0x43A3C6D8Ab17700F02678769D707A8506979f90a);
        issueCard(0xB648A7c8eD58108194888Fb4701543E134EC91f9);
        issueCard(0x68a9d79EEd5E5fA3a76C9d28303f2Ccf65680665);
        issueCard(0x823887649977942A94003Dd970C05Aa3B6647A60);
        issueCard(0x39Da47B370EaeF6E2eA30270466071cb1e0A52CC);
        issueCard(0x63DCe2d2F21d681aBa83521D7EdaC276C00c2a01);
        issueCard(0xcBfF2cC509eafdE2e7176660A7B09fFD27433a6f);
        issueCard(0x932fE9C7Aa5bcd89822B590f15E2c42Fb1896Ea0);
        issueCard(0x89d2119b24E9535Bc3EBDE78A8f26a256272f24F);
        issueCard(0xD130f6b32E4D6e22a0E119b883Fa824206a9db9b);
        issueCard(0x327aBcA5aB769fF74dED50120197A8B77d037735);
        issueCard(0xc624053a439b58Bd136Cd16ada512eFC0a8f707D);
        issueCard(0xd62D756f6850991F79F17614B4f4B0FAdE3C87c2);
        issueCard(0x51f10B415b09936cBD39E32097603af9110B8d01);
        issueCard(0xbB4D0669a5EcbEFDF15e594bF4137aAb5E87b8a1);
        issueCard(0xec1A47D2a1991AaeB738C9f59fB735DCD5f4574b);
        issueCard(0xAacc237256d2Ea2063E8B6fd2F9811327a39579F);
        issueCard(0xEE52Bf933CFbA9a874B9757E5037695fC702b2C0);
        issueCard(0x275a8f8E57c873C393355f0A925A305B0E6D4354);
        issueCard(0xEADF5909f7b0Ff9F2d7837b4EcA68649446ed18f);
        issueCard(0x06f6e762C30c193dfD2D0d426707210dB1E407a7);
        issueCard(0x15D9C502F590192087dAC2e2676C82caC1e560d6);
        issueCard(0x66565277cfdb8f3F8e407BBe162a18f8f799C1e5);
        issueCard(0x3CAA2BcCC07eb4F2468cBC49361B7E2AD315C266);
        issueCard(0x6FB1E21c0590a4Bc1cc1C22881FdA02Ae6973fEF);
        issueCard(0x82Dad93aE893DE9d0015B9a9eE4229249Bd9875e);
        issueCard(0xCA7Cc5231801A32754a108042AC0c3532b9ca8Ff);
        issueCard(0x3dD0e09437FB2a4848D36eb063bb54a7270ae2aA);
        issueCard(0x5c8d16c6d3Ba0eEcc3E1f641223d3744980B5E58);
        issueCard(0xc024D90cE1cdD63B0D6D2441575c58044A4c67d1);
        issueCard(0x776769Dc05fB6cFB7915dad855296F2f22538bb5);
        issueCard(0x8F7A119Fb68e4eD4341bEb69E32aF91712930DDD);
        issueCard(0xf666C24f9CA6D4f72AdDf08028Aa7CC80e48F135);
        issueCard(0xa23Fe6084BF11b82117BA0A529aDe79271009766);
        issueCard(0x78b2bd4926cE54D9C4f89a960922DaC386F5D5C5);
        issueCard(0x5aBE0e4C01Bddc040C2d3179D94F5CF6918A0479);
        issueCard(0x7bb2033847db5856530f287fB79Ee2f93441d96E);
        issueCard(0x33AaD2a62BAB912dEfde87Ed4f5B402125D7a0E3);
        issueCard(0xbA8f0a4b927a1352d9D4DCf544eBaa29cE289B3a);
        issueCard(0x73874C9b7953AA3Cdc05c928703c6aE83C4040EE);
        issueCard(0xAe34eb13cFba837f8b2839C561eE910598aC3C47);
        issueCard(0xAe34eb13cFba837f8b2839C561eE910598aC3C47);
        issueCard(0x4eA47B5aef9C97616586d6c2f326C88C65D2F67f);
        issueCard(0x2b0e52238Ad855b6FC05148BE17eb67Add6eB307);
        issueCard(0x9f5A16875d2FAf6a7b7b8eAEfDe0619421fb020b);
        issueCard(0xF592a8B6286a050D4D6077c8f07A19eD47D2bFA4);
        issueCard(0x7498b3F5dDf6139f1257cd43fC2EE58c658a987A);
        issueCard(0x3AC7970f5ab9014d8bd0af0B9BDd8072c8ba731D);
        issueCard(0x7E08cd0C07F98D5f2cA39d62Be19799aB827aF5a);
        issueCard(0x5254745B9579c177C9CCf0aac6E0e2F1dB4484Ea);
        issueCard(0x05f3c2FDbc013828E2090E15ffDd22892168B5F9);
        issueCard(0xd55B26Cf46B138c818cfC8722AC3FB06a0544559);
        issueCard(0x2fEa40F4af632B21968e478c80835F6b71Ad28DF);
        issueCard(0x09D1A2B76C35986EC1F9c19dAfb93CC9eDCF2F40);
        issueCard(0x85B2Cc7c0Aeabf19c1e15E3887166f544247371b);
        issueCard(0xBD82fDE36ABa3d1E6A056D5A33a4F02Df789829b);
        issueCard(0x3472bEA0374807c51d350A920a4Bb0A259322E12);
        issueCard(0x536F7d9f989E33742dA8822406d02cA28d288f05);
        issueCard(0xa88E4620ED86d3D3cc69F568C5086366c5EEF9Fc);
        issueCard(0xF62286b69a1D9Bb3179076cc3ba2ff8b1dAe1B7c);
        issueCard(0xd802a19F58c011DB1F61fA944535F5c43A706eE2);
        issueCard(0x20B4BAA7951Eb952F2FaB431a51EFa560cd153Bc);
        issueCard(0x7ff6e330B35c895DeD5e9B230a325aeF9F78924d);
        issueCard(0x324EC6dB2f0738d4f15DD63bA623EAA4218041C4);
        issueCard(0x92c04400E2d08f4Becd643aF043760fcEE710c30);
        issueCard(0x8d202E81FfB2D3Da80A4Db5787540f88BEDf309d);
        issueCard(0x0a1cd617215EB8C02fCb1d0B08df5C9B82240A76);
        issueCard(0x05A3C3D3180e34A2b215986E6FeDF51c660DE3B6);
        issueCard(0x1BD718F0085df0DedDCe804218C8B3c70Fac82b7);
        issueCard(0x6f68b6d07929B99b3e3e6E647383C65DcBA70498);
        issueCard(0x02cE8E0D042A2B16d95020cE959b91a8B92e2Ee8);
        issueCard(0x7Bfe41Ea4D4d1368D10A84556F892fF4F5691b79);
        issueCard(0x5fAB308F168fad0B0B1dF9B518eB3366d12a1Fae);
        issueCard(0xA4d917C157ce08c53D336fB4ADE1868b6FaE36F7);
        issueCard(0x7D1072a6c2148b1ccAB3F9aA34555Ff7B22Ebd7c);
        issueCard(0xd6d5b13976CbF94703794bb96a5858ccaaBc63E0);
        issueCard(0xc390A2572E07533AcF6480311b75Fac7fa4BF498);
        issueCard(0xea53334A77B3a779A031FE9210036d8Fa4aA639B);
        issueCard(0x576468BA4f84b630213b9afeEd846B9028A573Be);
        issueCard(0x0C8a0b6C0e24Bd5f3C121dddd1cED0f56ccF0666);
        issueCard(0x09eA17757b648F97c5699806ea7BD87F5206F425);
        issueCard(0x5f93d99F5Fc313843C750dE4293F66c642ee4216);
        issueCard(0x07CEc5c2e69b0938fFFE0caa6EF1508557E12FDB);
        issueCard(0x27B7DD511CCE6FA49eeb79846c478E1D96b64145);
        issueCard(0x95750579C47c3ecaf419422E3f841e9976e7B447);
        issueCard(0xE410641a155be2a333d2f0e2D30c6863fA0BFe10);
        issueCard(0x46e1480e8E8C2767D926719Ff4072Aba3848C355);
        issueCard(0x39841fDDF2FdA2be6c60c9A910e4A2C6D692Df6A);
        issueCard(0xBC93E622e43D63A7F091fd223BB3030F56c296a3);
        issueCard(0xA539ba60D4D1086d1F21150C3186579efa991705);
        issueCard(0x7FB3d8a3595dF044c42d7622f9813244564B8977);
        issueCard(0xF48eECE024C878612Db464bA54c211534F903817);
        issueCard(0x785640B80c1147D7a45a0B60051d6aBF58Cae763);
        issueCard(0x36ea6AF4B00653ad236953dA4a1505632Cbe2163);
        issueCard(0x978Ed1225A9b3EaAaC1B0De4BD6BF0D1d2fE929f);
    }

    function issueCard(address _to) internal{
        totalSupply_ = totalSupply_ + 1;
        balances[_to] = 1;
        emit Transfer(address(0), _to, 1);
    }

    function buyCard(bytes32 data) public payable {
        require(numCardsPurchased < 100, "Cards sold out");
        require(msg.value >= 1 ether, "min 1 ether");
        emit CardPurchased(msg.sender, numCardsPurchased,data);
        peepethAccount.transfer(msg.value);
        numCardsPurchased++;
    }

}