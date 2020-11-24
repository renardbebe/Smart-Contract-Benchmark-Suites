 

 
 
 
 
contract BranchSender {
   
   
  bool public isRightBranch;

   
   
   
   
   
  function BranchSender(uint blockNumber, bytes32 blockHash) {
    if (msg.value > 0) throw;  

    isRightBranch = (block.number < 256 || blockNumber > block.number - 256) &&
                    (blockNumber < block.number) &&
                    (block.blockhash (blockNumber) == blockHash);
  }

   
  function () {
    throw;
  }

   
   
   
   
   
  function send (address recipient) {
    if (!isRightBranch) throw;
    if (!recipient.send (msg.value)) throw;
  }
}