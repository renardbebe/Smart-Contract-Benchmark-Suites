 

pragma solidity 0.4.24;

 

 
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

   
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

   
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}

 

 
interface ICrowdsale {
    function kyc(address _address) external returns (bool);
    function wallet() external returns (address);
    function minContribution() external returns (uint256);
    function getCurrentRate() external returns (uint256);
}

 
interface IToken {
    function mint(address _to, uint256 _amount) external returns (bool);
}

 
contract INXCommitment is Pausable {
    using SafeMath for uint256;

    address internal sender;

    uint256 internal tokenBalance;

    bool internal refunding = false;

    ICrowdsale internal crowdsale;
    IToken internal token;

     
    event Commit(
        address indexed sender,
        uint256 value,
        uint256 rate,
        uint256 amount
    );

     
    event Refund(
        address indexed sender,
        uint256 value
    );

     
    event RefundToggle(
        bool newValue
    );

     
    event Redeem(
        address indexed sender,
        uint256 value,
        uint256 amount
    );

    constructor(address _sender, ICrowdsale _crowdsale, IToken _token) public  {
        sender = _sender;
        crowdsale = _crowdsale;
        token = _token;
    }

     
    function() external payable {
        commit();
    }

     
    function refund() external whenNotPaused returns (bool) {
        require(refunding, "Must be in refunding state");

        require(tokenBalance > 0, "Token balance must be positive");

        tokenBalance = 0;

        uint256 refundWeiBalance = address(this).balance;
        sender.transfer(refundWeiBalance);

        emit Refund(
            sender,
            refundWeiBalance
        );

        return true;
    }

     
    function redeem() external whenNotPaused returns (bool) {
        require(!refunding, "Must not be in refunding state");

        require(tokenBalance > 0, "Token balance must be positive");

        bool kyc = crowdsale.kyc(sender);
        require(kyc, "Sender must have passed KYC");

        uint256 redeemTokenBalance = tokenBalance;
        tokenBalance = 0;

        uint256 redeemWeiBalance = address(this).balance;

        address wallet = crowdsale.wallet();
        wallet.transfer(redeemWeiBalance);

        require(token.mint(sender, redeemTokenBalance), "Unable to mint INX tokens");

        emit Redeem(
            sender,
            redeemWeiBalance,
            redeemTokenBalance
        );

        return true;
    }

     
    function commit() public payable whenNotPaused returns (bool) {
        require(!refunding, "Must not be in refunding state");
        require(sender == msg.sender, "Can only commit from the predefined sender address");

        uint256 weiAmount = msg.value;
        uint256 minContribution = crowdsale.minContribution();

        require(weiAmount >= minContribution, "Commitment value below minimum");

         
        uint256 rate = crowdsale.getCurrentRate();

         
        uint256 tokens = weiAmount.mul(rate);
        tokenBalance = tokenBalance.add(tokens);

        emit Commit(
            sender,
            weiAmount,
            rate,
            tokens
        );

        return true;
    }

     
    function senderTokenBalance() public view returns (uint256) {
        return tokenBalance;
    }

     
    function senderWeiBalance() public view returns (uint256) {
        return address(this).balance;
    }

     
    function senderAddress() public view returns (address) {
        return sender;
    }

     
    function inxCrowdsale() public view returns (address) {
        return crowdsale;
    }


     
    function inxToken() public view returns (address) {
        return token;
    }


     
    function isRefunding() public view returns (bool) {
        return refunding;
    }

     
    function toggleRefunding() external onlyOwner {
        refunding = !refunding;

        emit RefundToggle(refunding);
    }
}