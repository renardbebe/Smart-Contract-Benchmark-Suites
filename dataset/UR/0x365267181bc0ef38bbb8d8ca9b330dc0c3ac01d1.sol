 

 
pragma solidity ^0.4.18;

contract mhethkeeper {

     

     
    address public recipient;            
    uint256 public amountToTransfer;         


     
    bool public isFinalized;             
    uint public minVotes;                
    uint public curVotes;                
    address public owner;                
    uint public mgrCount;                
    mapping (uint => bool) public mgrVotes;      
    mapping (uint => address) public mgrAddress;  

     
    function mhethkeeper() public{
        owner = msg.sender;
        isFinalized = false;
        curVotes = 0;
        mgrCount = 0;
        minVotes = 2;
    }

     
    function AddManager(address _manager) public{
        if (!isFinalized && (msg.sender == owner)){
            mgrCount = mgrCount + 1;
            mgrAddress[mgrCount] = _manager;
            mgrVotes[mgrCount] = false;
        } else {
            revert();
        }
    }

     
    function Finalize() public{
        if (!isFinalized && (msg.sender == owner)){
            isFinalized = true;
        } else {
            revert();
        }
    }

     
    function SetAction(address _recipient, uint256 _amountToTransfer) public{
        if (!isFinalized){
            revert();
        }

        if (IsManager(msg.sender)){
            if (this.balance < _amountToTransfer){
                revert();
            }
            recipient = _recipient;
            amountToTransfer = _amountToTransfer;
            
            for (uint i = 1; i <= mgrCount; i++) {
                mgrVotes[i] = false;
            }
            curVotes = 0;
        } else {
            revert();
        }
    }

     
    function Approve(address _recipient, uint256 _amountToTransfer) public{
        if (!isFinalized){
            revert();
        }
        if (!((recipient == _recipient) && (amountToTransfer == _amountToTransfer))){
            revert();
        }

        for (uint i = 1; i <= mgrCount; i++) {
            if (mgrAddress[i] == msg.sender){
                if (!mgrVotes[i]){
                    mgrVotes[i] = true;
                    curVotes = curVotes + 1;

                    if (curVotes >= minVotes){
                        recipient.transfer(amountToTransfer);
                        NullSettings();
                    } 
                } else {
                    revert();
                }
            }
        }
    }

     
    function () public payable {}
    
     
    function NullSettings() private{
        recipient = address(0x0);
        amountToTransfer = 0;
        curVotes = 0;
        for (uint i = 1; i <= mgrCount; i++) {
            mgrVotes[i] = false;
        }

    }

     
    function IsManager(address _manager) private view returns(bool){
        for (uint i = 1; i <= mgrCount; i++) {
            if (mgrAddress[i] == _manager){
                return true;
            }
        }
        return false;
    }
}