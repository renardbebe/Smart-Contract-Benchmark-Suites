 

 
contract BranchWallet {
   
  address public owner;
    
   
   
  bool public isRightBranch;

   
   
   
   
  function BranchWallet (address _owner, bool _isRightBranch) {
    owner = _owner;
    isRightBranch = _isRightBranch;
  }

   
  function () {
    if (!isRightBranch) throw;
  }

   
   
   
   
   
  function send (address _to, uint _value) {
    if (!isRightBranch) throw;
    if (msg.sender != owner) throw;
    if (!_to.send (_value)) throw;
  }

   
   
   
   
   
  function execute (address _to, uint _value, bytes _data) {
    if (!isRightBranch) throw;
    if (msg.sender != owner) throw;
    if (!_to.call.value (_value)(_data)) throw;
  }
}

 
 
contract BranchSender {
   
   
  bool public isRightBranch;
}