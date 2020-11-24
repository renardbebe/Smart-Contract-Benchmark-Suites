 

pragma solidity ^0.4.11;

 
 
 
 
contract Splitter {
     
     
     
     
     
    mapping(address => uint) public amountsWithdrew;

     
     
    mapping(address => bool) public between;

     
    uint public count;

     
    uint public totalInput;

     

     
    function Splitter(address[] addrs) {
        count = addrs.length;

        for (uint i = 0; i < addrs.length; i++) {
             
            address included = addrs[i];
            between[included] = true;
        }
    }

     
     
     

     
     
     
     
     
    function withdraw(uint amount) {
        Splitter.withdrawInternal(amount, false);
    }

     
     
    function withdrawAll() {
        Splitter.withdrawInternal(0, true);
    }

     
     

     
     
     
     
     
     
     
    function withdrawInternal(uint requested, bool all) internal {
         
         
        require(between[msg.sender]);

         
        uint available = Splitter.balance();
        uint transferring = 0;

        if (all) { transferring = available; }
        else { available = requested; }

         
         
        require(transferring <= available);

         
         
        amountsWithdrew[msg.sender] += transferring;

         
         
        msg.sender.transfer(transferring);
    }

     
     
     
     
     
     

     
    function balance() constant returns (uint) {
        if (!between[msg.sender]) {
             
            return 0;
        }

         
         
        uint share = totalInput / count;
        uint withdrew = amountsWithdrew[msg.sender];
        uint available = share - withdrew;

        assert(available >= 0 && available <= share);

        return available;
    }

     
     
    function() payable {
        totalInput += msg.value;
    }
}