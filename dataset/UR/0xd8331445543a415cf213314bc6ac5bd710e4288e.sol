 

 
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

 
 contract ERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
 }

 

contract OptionsEscrow is Ownable {
    using SafeMath for uint;

    struct Option {
        address beneficiary;
        uint tokenAmount;
        uint strikeMultiple;
        uint128 vestUntil;
        uint128 expiration;
    }

    address public token;
    uint public issuedTokens;
    uint64 public optionsCount;
    mapping (address => Option) public grantedOptions;

    event GrantOption(address indexed beneficiary, uint tokenAmount, uint strikeMultiple, uint128 vestUntil, uint128 expiration);
    event ExerciseOption(address indexed beneficiary, uint exercisedAmount, uint strikeMultiple);
    event ReclaimOption(address indexed beneficiary);

     
    constructor(address _token) public {
         

        token = _token;
        issuedTokens = 0;
        optionsCount = 0;
    }

     
    function issueOption(address _beneficiary,
                            uint _tokenAmount,
                            uint _strikeMultiple,
                         uint128 _vestUntil,
                         uint128 _expiration) onlyOwner public {
        uint _issuedTokens = issuedTokens.add(_tokenAmount);

        require(_tokenAmount > 0 &&
                _expiration > _vestUntil &&
                _vestUntil > block.timestamp &&
                ERC20(token).balanceOf(this) > _issuedTokens);

        Option memory option = Option(_beneficiary, _tokenAmount, _strikeMultiple, _vestUntil, _expiration);

        grantedOptions[_beneficiary] = option;
        optionsCount++;
        issuedTokens = _issuedTokens;

        emit GrantOption(_beneficiary, _tokenAmount, _strikeMultiple, _vestUntil, _expiration);
    }

     
    function () public payable {
        Option storage option = grantedOptions[msg.sender];

        require(option.beneficiary == msg.sender &&
                option.vestUntil <= block.timestamp &&
                option.expiration > block.timestamp &&
                option.tokenAmount > 0);

        uint amountExercised = msg.value.mul(option.strikeMultiple);
        if(amountExercised > option.tokenAmount) {
            amountExercised = option.tokenAmount;
        }

        option.tokenAmount = option.tokenAmount.sub(amountExercised);
        issuedTokens = issuedTokens.sub(amountExercised);
        require(ERC20(token).transfer(msg.sender, amountExercised));

        emit ExerciseOption(msg.sender, amountExercised, option.strikeMultiple);
    }

     
    function reclaimExpiredOptionTokens(address[] beneficiaries) public onlyOwner returns (uint reclaimedTokenAmount) {
        reclaimedTokenAmount = 0;
        for (uint i=0; i<beneficiaries.length; i++) {
            Option storage option = grantedOptions[beneficiaries[i]];
            if (option.expiration <= block.timestamp) {
                reclaimedTokenAmount = reclaimedTokenAmount.add(option.tokenAmount);
                option.tokenAmount = 0;

                emit ReclaimOption(beneficiaries[i]);
            }
        }
        issuedTokens = issuedTokens.sub(reclaimedTokenAmount);
        require(ERC20(token).transfer(owner, reclaimedTokenAmount));
    }

     
    function reclaimUnissuedTokens() public onlyOwner returns (uint reclaimedTokenAmount) {
        reclaimedTokenAmount = ERC20(token).balanceOf(this) - issuedTokens;
        require(ERC20(token).transfer(owner, reclaimedTokenAmount));
    }

     
    function withdrawEth() public onlyOwner {
        owner.transfer(address(this).balance);
    }

     
    function getOption(address _beneficiary) public constant returns(address beneficiary,
                                                          uint tokenAmount,
                                                          uint strikeMultiple,
                                                          uint128 vestUntil,
                                                          uint128 expiration) {
        Option memory option = grantedOptions[_beneficiary];
        beneficiary = option.beneficiary;
        tokenAmount = option.tokenAmount;
        strikeMultiple = option.strikeMultiple;
        vestUntil = option.vestUntil;
        expiration = option.expiration;
    }
}