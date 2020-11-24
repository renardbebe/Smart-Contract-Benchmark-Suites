 

 
 
contract BirthdayGift {
     
     
    address public recipient;

     
    uint public birthday;

     
     
     
     
    event HappyBirthday (address recipient, uint value);

     
     
     
     
    function BirthdayGift (address _recipient, uint _birthday)
    {
         
        recipient = _recipient;

         
        birthday = _birthday;
    }

     
    function ()
    {
         
        if (block.timestamp >= birthday) throw;
    }

     
    function Take ()
    {
         
        if (msg.sender != recipient) throw;

         
        if (block.timestamp < birthday) throw;

         
        HappyBirthday (recipient, this.balance);

         
        if (!recipient.send (this.balance)) throw;
    }
}