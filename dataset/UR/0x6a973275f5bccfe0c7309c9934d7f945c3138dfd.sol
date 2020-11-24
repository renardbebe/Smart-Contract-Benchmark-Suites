 

pragma solidity 0.5.6;

 
 
 
 
 
contract SafeMath {
     
    constructor() public {
    }

     
    function safeAdd(uint256 _x, uint256 _y) pure internal returns (uint256) {
        uint256 z = _x + _y;
        assert(z >= _x);
        return z;
    }

     
    function safeSub(uint256 _x, uint256 _y) pure internal returns (uint256) {
        assert(_x >= _y);
        return _x - _y;
    }

     
    function safeMul(uint256 _x, uint256 _y) pure internal returns (uint256) {
        uint256 z = _x * _y;
        assert(_x == 0 || z / _x == _y);
        return z;
    }
}

 
 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract MessageTransport is SafeMath, Ownable {

   
   
   
   
   
   
  event InviteEvent(address indexed _toAddr, address indexed _fromAddr);
  event MessageEvent(uint indexed _id1, uint indexed _id2, uint indexed _id3,
                     address _fromAddr, address _toAddr, address _via, uint _txCount, uint _rxCount, uint _attachmentIdx, uint _ref, bytes message);
  event MessageTxEvent(address indexed _fromAddr, uint indexed _txCount, uint _id);
  event MessageRxEvent(address indexed _toAddr, uint indexed _rxCount, uint _id);


   
   
   
   
  struct Account {
    bool isValid;
    uint messageFee;            
    uint spamFee;               
    uint feeBalance;            
    uint recvMessageCount;      
    uint sentMessageCount;      
    bytes publicKey;            
    bytes encryptedPrivateKey;  
    mapping (address => uint256) peerRecvMessageCount;
    mapping (uint256 => uint256) recvIds;
    mapping (uint256 => uint256) sentIds;
  }


   
   
   
  bool public isLocked;
  address public tokenAddr;
  uint public messageCount;
  uint public retainedFeesBalance;
  mapping (address => bool) public trusted;
  mapping (address => Account) public accounts;


   
   
   
  modifier trustedOnly {
    require(trusted[msg.sender] == true, "trusted only");
    _;
  }


   
   
   
  constructor(address _tokenAddr) public {
    tokenAddr = _tokenAddr;
  }
  function setTrust(address _trustedAddr, bool _trust) public onlyOwner {
    trusted[_trustedAddr] = _trust;
  }


   
   
   
   
   
   
   
  function register(uint256 _messageFee, uint256 _spamFee, bytes memory _publicKey, bytes memory _encryptedPrivateKey) public {
    Account storage _account = accounts[msg.sender];
    require(_account.isValid == false, "account already registered");
    _account.publicKey = _publicKey;
    _account.encryptedPrivateKey = _encryptedPrivateKey;
    _account.isValid = true;
    _modifyAccount(_account, _messageFee, _spamFee);
  }
  function modifyAccount(uint256 _messageFee, uint256 _spamFee) public {
    Account storage _account = accounts[msg.sender];
    require(_account.isValid == true, "not registered");
    _modifyAccount(_account, _messageFee, _spamFee);
  }
  function _modifyAccount(Account storage _account, uint256 _messageFee, uint256 _spamFee) internal {
    _account.messageFee = _messageFee;
    _account.spamFee = _spamFee;
  }


   
   
   
  function getPeerMessageCount(address _from, address _to) public view returns(uint256 _messageCount) {
    Account storage _account = accounts[_to];
    _messageCount = _account.peerRecvMessageCount[_from];
  }



   
   
   
   
  function getRecvMsgs(address _to, uint256 _startIdx, uint256 _maxResults) public view returns(uint256 _idx, uint256[] memory _messageIds) {
    uint _count = 0;
    Account storage _recvAccount = accounts[_to];
    uint256 _recvMessageCount = _recvAccount.recvMessageCount;
    _messageIds = new uint256[](_maxResults);
    mapping(uint256 => uint256) storage _recvIds = _recvAccount.recvIds;
     
    for (_idx = _startIdx; _idx < _recvMessageCount; ++_idx) {
      _messageIds[_count] = _recvIds[_idx];
      if (++_count >= _maxResults)
        break;
    }
  }

   
   
   
   
  function getSentMsgs(address _from, uint256 _startIdx, uint256 _maxResults) public view returns(uint256 _idx, uint256[] memory _messageIds) {
    uint _count = 0;
    Account storage _sentAccount = accounts[_from];
    uint256 _sentMessageCount = _sentAccount.sentMessageCount;
    _messageIds = new uint256[](_maxResults);
    mapping(uint256 => uint256) storage _sentIds = _sentAccount.sentIds;
     
    for (_idx = _startIdx; _idx < _sentMessageCount; ++_idx) {
      _messageIds[_count] = _sentIds[_idx];
      if (++_count >= _maxResults)
        break;
    }
  }


   
   
   
   
  function getFee(address _toAddr) public view returns(uint256 _fee) {
    Account storage _sendAccount = accounts[msg.sender];
    Account storage _recvAccount = accounts[_toAddr];
    if (_sendAccount.peerRecvMessageCount[_toAddr] == 0)
      _fee = _recvAccount.spamFee;
    else
      _fee = _recvAccount.messageFee;
  }
  function getFee(address _fromAddr, address _toAddr) public view trustedOnly returns(uint256 _fee) {
    Account storage _sendAccount = accounts[_fromAddr];
    Account storage _recvAccount = accounts[_toAddr];
    if (_sendAccount.peerRecvMessageCount[_toAddr] == 0)
      _fee = _recvAccount.spamFee;
    else
      _fee = _recvAccount.messageFee;
  }


   
   
   
   
   
   
   
  function sendMessage(address _toAddr, uint attachmentIdx, uint _ref, bytes memory _message) public payable returns (uint _messageId) {
    uint256 _noDataLength = 4 + 32 + 32 + 32 + 64;
    _messageId = doSendMessage(_noDataLength, msg.sender, _toAddr, address(0), attachmentIdx, _ref, _message);
  }
  function sendMessage(address _fromAddr, address _toAddr, uint attachmentIdx, uint _ref, bytes memory _message) public payable trustedOnly returns (uint _messageId) {
    uint256 _noDataLength = 4 + 32 + 32 + 32 + 32 + 64;
    _messageId = doSendMessage(_noDataLength, _fromAddr, _toAddr, msg.sender, attachmentIdx, _ref, _message);
  }


  function doSendMessage(uint256 _noDataLength, address _fromAddr, address _toAddr, address _via, uint attachmentIdx, uint _ref, bytes memory _message) internal returns (uint _messageId) {
    Account storage _sendAccount = accounts[_fromAddr];
    Account storage _recvAccount = accounts[_toAddr];
    require(_sendAccount.isValid == true, "sender not registered");
    require(_recvAccount.isValid == true, "recipient not registered");
     
     
     
    if (msg.data.length > _noDataLength) {
      if (_sendAccount.peerRecvMessageCount[_toAddr] == 0)
        require(msg.value >= _recvAccount.spamFee, "spam fee is insufficient");
      else
        require(msg.value >= _recvAccount.messageFee, "fee is insufficient");
      messageCount = safeAdd(messageCount, 1);
      _recvAccount.recvIds[_recvAccount.recvMessageCount] = messageCount;
      _sendAccount.sentIds[_sendAccount.sentMessageCount] = messageCount;
      _recvAccount.recvMessageCount = safeAdd(_recvAccount.recvMessageCount, 1);
      _sendAccount.sentMessageCount = safeAdd(_sendAccount.sentMessageCount, 1);
      emit MessageEvent(messageCount, messageCount, messageCount, _fromAddr, _toAddr, _via, _sendAccount.sentMessageCount, _recvAccount.recvMessageCount, attachmentIdx, _ref, _message);
      emit MessageTxEvent(_fromAddr, _sendAccount.sentMessageCount, messageCount);
      emit MessageRxEvent(_toAddr, _recvAccount.recvMessageCount, messageCount);
       
      _messageId = messageCount;
    } else {
      emit InviteEvent(_toAddr, _fromAddr);
      _messageId = 0;
    }
    uint _retainAmount = safeMul(msg.value, 30) / 100;
    retainedFeesBalance = safeAdd(retainedFeesBalance, _retainAmount);
    _recvAccount.feeBalance = safeAdd(_recvAccount.feeBalance, safeSub(msg.value, _retainAmount));
    _recvAccount.peerRecvMessageCount[_fromAddr] = safeAdd(_recvAccount.peerRecvMessageCount[_fromAddr], 1);
  }


   
   
   
  function withdraw() public {
    Account storage _account = accounts[msg.sender];
    uint _amount = _account.feeBalance;
    _account.feeBalance = 0;
    msg.sender.transfer(_amount);
  }


   
   
   
  function withdrawRetainedFees() public {
    uint _amount = retainedFeesBalance / 2;
    address(0).transfer(_amount);
    _amount = safeSub(retainedFeesBalance, _amount);
    retainedFeesBalance = 0;
    (bool paySuccess, ) = tokenAddr.call.value(_amount)("");
    require(paySuccess, "failed to transfer fees");
  }

}