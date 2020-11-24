 

 

pragma solidity >=0.4.24 <0.6.0;


 
contract Initializable {

   
  bool private initialized;

   
  bool private initializing;

   
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

   
  function isConstructor() private view returns (bool) {
     
     
     
     
     
    uint256 cs;
    assembly { cs := extcodesize(address) }
    return cs == 0;
  }

   
  uint256[50] private ______gap;
}

 

pragma solidity ^0.5.0;

 
contract IRelayRecipient {
     
    function getHubAddr() public view returns (address);

     
    function acceptRelayedCall(
        address relay,
        address from,
        bytes calldata encodedFunction,
        uint256 transactionFee,
        uint256 gasPrice,
        uint256 gasLimit,
        uint256 nonce,
        bytes calldata approvalData,
        uint256 maxPossibleCharge
    )
        external
        view
        returns (uint256, bytes memory);

     
    function preRelayedCall(bytes calldata context) external returns (bytes32);

     
    function postRelayedCall(bytes calldata context, bool success, uint256 actualCharge, bytes32 preRetVal) external;
}

 

pragma solidity ^0.5.0;

 
contract IRelayHub {
     

     
    function stake(address relayaddr, uint256 unstakeDelay) external payable;

     
    event Staked(address indexed relay, uint256 stake, uint256 unstakeDelay);

     
    function registerRelay(uint256 transactionFee, string memory url) public;

     
    event RelayAdded(address indexed relay, address indexed owner, uint256 transactionFee, uint256 stake, uint256 unstakeDelay, string url);

     
    function removeRelayByOwner(address relay) public;

     
    event RelayRemoved(address indexed relay, uint256 unstakeTime);

     
    function unstake(address relay) public;

     
    event Unstaked(address indexed relay, uint256 stake);

     
    enum RelayState {
        Unknown,  
        Staked,  
        Registered,  
        Removed     
    }

     
    function getRelay(address relay) external view returns (uint256 totalStake, uint256 unstakeDelay, uint256 unstakeTime, address payable owner, RelayState state);

     

     
    function depositFor(address target) public payable;

     
    event Deposited(address indexed recipient, address indexed from, uint256 amount);

     
    function balanceOf(address target) external view returns (uint256);

     
    function withdraw(uint256 amount, address payable dest) public;

     
    event Withdrawn(address indexed account, address indexed dest, uint256 amount);

     

     
    function canRelay(
        address relay,
        address from,
        address to,
        bytes memory encodedFunction,
        uint256 transactionFee,
        uint256 gasPrice,
        uint256 gasLimit,
        uint256 nonce,
        bytes memory signature,
        bytes memory approvalData
    ) public view returns (uint256 status, bytes memory recipientContext);

     
    enum PreconditionCheck {
        OK,                          
        WrongSignature,              
        WrongNonce,                  
        AcceptRelayedCallReverted,   
        InvalidRecipientStatusCode   
    }

     
    function relayCall(
        address from,
        address to,
        bytes memory encodedFunction,
        uint256 transactionFee,
        uint256 gasPrice,
        uint256 gasLimit,
        uint256 nonce,
        bytes memory signature,
        bytes memory approvalData
    ) public;

     
    event CanRelayFailed(address indexed relay, address indexed from, address indexed to, bytes4 selector, uint256 reason);

     
    event TransactionRelayed(address indexed relay, address indexed from, address indexed to, bytes4 selector, RelayCallStatus status, uint256 charge);

     
    enum RelayCallStatus {
        OK,                       
        RelayedCallFailed,        
        PreRelayedFailed,         
        PostRelayedFailed,        
        RecipientBalanceChanged   
    }

     
    function requiredGas(uint256 relayedCallStipend) public view returns (uint256);

     
    function maxPossibleCharge(uint256 relayedCallStipend, uint256 gasPrice, uint256 transactionFee) public view returns (uint256);

      
      
     
     

     
    function penalizeRepeatedNonce(bytes memory unsignedTx1, bytes memory signature1, bytes memory unsignedTx2, bytes memory signature2) public;

     
    function penalizeIllegalTransaction(bytes memory unsignedTx, bytes memory signature) public;

     
    event Penalized(address indexed relay, address sender, uint256 amount);

     
    function getNonce(address from) external view returns (uint256);
}

 

pragma solidity ^0.5.0;


 
contract Context is Initializable {
     
     
    constructor () internal { }
     

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;  
        return msg.data;
    }
}

 

pragma solidity ^0.5.0;





 
contract GSNRecipient is Initializable, IRelayRecipient, Context {
    function initialize() public initializer {
        if (_relayHub == address(0)) {
            setDefaultRelayHub();
        }
    }

    function setDefaultRelayHub() public {
        _upgradeRelayHub(0xD216153c06E857cD7f72665E0aF1d7D82172F494);
    }

     
    address private _relayHub;

    uint256 constant private RELAYED_CALL_ACCEPTED = 0;
    uint256 constant private RELAYED_CALL_REJECTED = 11;

     
    uint256 constant internal POST_RELAYED_CALL_MAX_GAS = 100000;

     
    event RelayHubChanged(address indexed oldRelayHub, address indexed newRelayHub);

     
    function getHubAddr() public view returns (address) {
        return _relayHub;
    }

     
    function _upgradeRelayHub(address newRelayHub) internal {
        address currentRelayHub = _relayHub;
        require(newRelayHub != address(0), "GSNRecipient: new RelayHub is the zero address");
        require(newRelayHub != currentRelayHub, "GSNRecipient: new RelayHub is the current one");

        emit RelayHubChanged(currentRelayHub, newRelayHub);

        _relayHub = newRelayHub;
    }

     
     
     
    function relayHubVersion() public view returns (string memory) {
        this;  
        return "1.0.0";
    }

     
    function _withdrawDeposits(uint256 amount, address payable payee) internal {
        IRelayHub(_relayHub).withdraw(amount, payee);
    }

     
     
     
     

     
    function _msgSender() internal view returns (address payable) {
        if (msg.sender != _relayHub) {
            return msg.sender;
        } else {
            return _getRelayedCallSender();
        }
    }

     
    function _msgData() internal view returns (bytes memory) {
        if (msg.sender != _relayHub) {
            return msg.data;
        } else {
            return _getRelayedCallData();
        }
    }

     
     

     
    function preRelayedCall(bytes calldata context) external returns (bytes32) {
        require(msg.sender == getHubAddr(), "GSNRecipient: caller is not RelayHub");
        return _preRelayedCall(context);
    }

     
    function _preRelayedCall(bytes memory context) internal returns (bytes32);

     
    function postRelayedCall(bytes calldata context, bool success, uint256 actualCharge, bytes32 preRetVal) external {
        require(msg.sender == getHubAddr(), "GSNRecipient: caller is not RelayHub");
        _postRelayedCall(context, success, actualCharge, preRetVal);
    }

     
    function _postRelayedCall(bytes memory context, bool success, uint256 actualCharge, bytes32 preRetVal) internal;

     
    function _approveRelayedCall() internal pure returns (uint256, bytes memory) {
        return _approveRelayedCall("");
    }

     
    function _approveRelayedCall(bytes memory context) internal pure returns (uint256, bytes memory) {
        return (RELAYED_CALL_ACCEPTED, context);
    }

     
    function _rejectRelayedCall(uint256 errorCode) internal pure returns (uint256, bytes memory) {
        return (RELAYED_CALL_REJECTED + errorCode, "");
    }

     
    function _computeCharge(uint256 gas, uint256 gasPrice, uint256 serviceFee) internal pure returns (uint256) {
         
         
        return (gas * gasPrice * (100 + serviceFee)) / 100;
    }

    function _getRelayedCallSender() private pure returns (address payable result) {
         
         
         
         
         

         
         

         
        bytes memory array = msg.data;
        uint256 index = msg.data.length;

         
        assembly {
             
            result := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
        }
        return result;
    }

    function _getRelayedCallData() private pure returns (bytes memory) {
         
         

        uint256 actualDataLength = msg.data.length - 20;
        bytes memory actualData = new bytes(actualDataLength);

        for (uint256 i = 0; i < actualDataLength; ++i) {
            actualData[i] = msg.data[i];
        }

        return actualData;
    }
}

 

pragma solidity ^0.5.0;



 
contract Ownable is Initializable, Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    function initialize(address sender) public initializer {
        _owner = sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

     
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[50] private ______gap;
}

 

pragma solidity 0.5.12;

 
interface IChai {
   
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
   
  function join(address dst, uint wad) external;
  function exit(address src, uint wad) external;
  function draw(address src, uint wad) external;
  function move(address src, address dst, uint wad) external returns (bool);
}

 

pragma solidity ^0.5.0;

 
interface IERC20 {
   
  function totalSupply() external view returns (uint256);

   
  function balanceOf(address account) external view returns (uint256);

   
  function transfer(address recipient, uint256 amount) external returns (bool);

   
  function allowance(address owner, address spender) external view returns (uint256);

   
  function approve(address spender, uint256 amount) external returns (bool);

   
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

   
  event Transfer(address indexed from, address indexed to, uint256 value);

   
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

pragma solidity ^0.5.0;

 
interface ICERC20 {
   
   
   
  function totalSupply() external view returns (uint256);
  function transfer(address dst, uint amount) external returns (bool);
  function transferFrom(address src, address dst, uint amount) external returns (bool);
  function approve(address spender, uint amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint);
  function balanceOf(address owner) external view returns (uint);
  function balanceOfUnderlying(address owner) external returns (uint);
  function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);
  function borrowRatePerBlock() external view returns (uint);
  function supplyRatePerBlock() external view returns (uint);
  function totalBorrowsCurrent() external returns (uint);
  function borrowBalanceCurrent(address account) external returns (uint);
  function borrowBalanceStored(address account) external view returns (uint);
  function exchangeRateCurrent() external returns (uint);
  function exchangeRateStored() external view returns (uint);
  function getCash() external view returns (uint);
  function accrueInterest() external returns (uint);
  function seize(address liquidator, address borrower, uint seizeTokens) external returns (uint);
  function mint(uint mintAmount) external returns (uint);
  function redeem(uint redeemTokens) external returns (uint);
  function redeemUnderlying(uint redeemAmount) external returns (uint);
  function borrow(uint borrowAmount) external returns (uint);
  function repayBorrow(uint repayAmount) external returns (uint);
  function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint);
}

 

pragma solidity 0.5.12;







 
contract Swapper is Initializable, Ownable, GSNRecipient {

   

  mapping (address => bool) public isValidUser;
  IERC20 public daiContract;
  IChai public chaiContract;
  ICERC20 public cdaiContract;

  event DaiAddressChanged(address indexed previousAddress, address indexed newAddress);
  event ChaiAddressChanged(address indexed previousAddress, address indexed newAddress);
  event CdaiAddressChanged(address indexed previousAddress, address indexed newAddress);
  event AssertionError(string indexed message);

   
  function initialize() public initializer {
     
    Ownable.initialize(_msgSender());
    GSNRecipient.initialize();

     
    daiContract = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    chaiContract = IChai(0x06AF07097C9Eeb7fD685c692751D5C66dB49c215);
    cdaiContract = ICERC20(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643);

     
    approveChaiToSpendDai();
    approveCdaiToSpendDai();
  }

   
  modifier verifyId(uint256 _id) {
    require(
      _id == 0 ||
      _id == 1,
      "swapper/invalid-id-provided"
    );
    _;
  }

   
  function addUser(address _address) external onlyOwner {
    isValidUser[_address] = true;
  }


   
   
   

   
  function approveChaiToSpendDai() private {
    bool result = daiContract.approve(address(chaiContract), uint256(-1));
    require(result, "swapper/approve-chai-to-spend-dai-failed");
  }

   
  function resetChaiAllowance() private {
    bool result = daiContract.approve(address(chaiContract), 0);
    require(result, "swapper/reset-chai-allowance-failed");
  }


   
  function approveCdaiToSpendDai() private {
    bool result = daiContract.approve(address(cdaiContract), uint256(-1));
    require(result, "swapper/approve-cdai-to-spend-dai-failed");
  }

   
  function resetCdaiAllowance() private {
    bool result = daiContract.approve(address(cdaiContract), 0);
    require(result, "swapper/reset-cdai-allowance-failed");
  }


   
   
   


   
  function updateDaiAddress(address _newAddress) external onlyOwner {
    emit DaiAddressChanged(address(daiContract), _newAddress);
    daiContract = IERC20(_newAddress);
  }

   
  function updateChaiAddress(address _newAddress) external onlyOwner {
    resetChaiAllowance();
    emit ChaiAddressChanged(address(chaiContract), _newAddress);
    chaiContract = IChai(_newAddress);
    approveChaiToSpendDai();
  }

   
  function updateCdaiAddress(address _newAddress) external onlyOwner {
    resetCdaiAllowance();
    emit CdaiAddressChanged(address(cdaiContract), _newAddress);
    cdaiContract = ICERC20(_newAddress);
    approveCdaiToSpendDai();
  }


   
   
   

   

   
   
  function swapChaiForDai(uint256 _daiAmount) private {
    address _user = _msgSender();
    if (_daiAmount == uint256(-1)) {
       
      uint256 _chaiBalance = chaiContract.balanceOf(_user);
      chaiContract.exit(_user, _chaiBalance);
    } else {
       
      chaiContract.draw(_user, _daiAmount);
    }
  }

   
  function swapDaiForChai() private {
    uint256 _daiBalance = daiContract.balanceOf(address(this));
    chaiContract.join(_msgSender(), _daiBalance);
  }

   
   
  function swapCdaiForDai(uint256 _daiAmount) private {
    address _user = _msgSender();
    if (_daiAmount == uint256(-1)) {
      uint256 _cdaiBalance = cdaiContract.balanceOf(address(this));
      require(cdaiContract.redeem(_cdaiBalance) == 0, "swapper/max-cdai-redemption-failed");
    } else {
      require(cdaiContract.redeemUnderlying(_daiAmount) == 0, "swapper/partial-cdai-redemption-failed");
    }
  }

  uint public test;
  uint public test2;
  uint public result;
  uint public test3;
   
  function swapDaiForCdai() private {
    uint256 _daiBalance = daiContract.balanceOf(address(this));
    test = _daiBalance;
    result = cdaiContract.mint(_daiBalance);
    require(result == 0, "swapper/cdai-mint-failed");
    test2 = daiContract.balanceOf(address(this));
    test3 = cdaiContract.balanceOf(address(this));
     
     
  }


   


   
  function composeSwap(uint256 _srcId, uint256 _destId, uint256 _daiAmount) external
    verifyId(_srcId)
    verifyId(_destId)
  {
     
    if      (_srcId == 0) { swapChaiForDai(_daiAmount); }
    else if (_srcId == 1) { swapCdaiForDai(_daiAmount); }
    else    { emit AssertionError("Invalid _srcId got through"); }

     
    if      (_destId == 0) { swapDaiForChai(); }
    else if (_destId == 1) { swapDaiForCdai(); }
    else    { emit AssertionError("Invalid _destId got through"); }
  }

  function composeSwap_chaiToDai(uint256 _srcId, uint256 _daiAmount) external verifyId(_srcId) {
     
    if      (_srcId == 0) { swapChaiForDai(_daiAmount); }
    else if (_srcId == 1) { swapCdaiForDai(_daiAmount); }
    else    { emit AssertionError("Invalid _srcId got through"); }
  }

  function composeSwap_daiToCdai(uint256 _destId) external verifyId(_destId) {
     
    if      (_destId == 0) { swapDaiForChai(); }
    else if (_destId == 1) { swapDaiForCdai(); }
    else    { emit AssertionError("Invalid _destId got through"); }
  }


   

   
  function withdrawDai(address _destination) private {
    uint256 _daiBalance = daiContract.balanceOf(address(this));
    daiContract.transfer(_destination, _daiBalance);
  }

   
   

   
  function withdrawChaiAsDai(address _destination, uint256 _daiAmount) external {
    swapChaiForDai(_daiAmount);
    withdrawDai(_destination);
  }


   
   
   

  uint256 public count;
  function increaseCount() external {
    count += 1;
  }

   
  function transferChai(address _recipient, uint256 _daiAmount) external {
    bool _result = chaiContract.move(_msgSender(), _recipient, _daiAmount);
    require(_result, "swapper/chai-transfer-failed");
  }

     
   
   

   
  function acceptRelayedCall(
    address relay,
    address from,
    bytes calldata encodedFunction,
    uint256 transactionFee,
    uint256 gasPrice,
    uint256 gasLimit,
    uint256 nonce,
    bytes calldata approvalData,
    uint256 maxPossibleCharge
  ) external view returns (uint256, bytes memory) {
     
     
     
     
     
     

     
    return _approveRelayedCall();
  }

   
  function _preRelayedCall(bytes memory context) internal returns (bytes32) {
  }

   
  function _postRelayedCall(bytes memory context, bool, uint256 actualCharge, bytes32) internal {
  }

  function setRelayHubAddress() public {
    if(getHubAddr() == address(0)) {
      _upgradeRelayHub(0xD216153c06E857cD7f72665E0aF1d7D82172F494);
    }
  }

  function getRecipientBalance() public view returns (uint) {
    return IRelayHub(getHubAddr()).balanceOf(address(this));
  }
}