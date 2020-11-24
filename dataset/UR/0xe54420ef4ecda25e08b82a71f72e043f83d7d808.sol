 

contract TheRichestMan {
    address owner;

    address public theRichest;
    uint public treasure=0;
    uint public withdrawDate=0;

    function TheRichestMan(address _owner)
    {
        owner=_owner;
    }

    function () public payable{
        require(treasure < msg.value);
        treasure = msg.value;
        withdrawDate = now + 2 days;
        theRichest = msg.sender;
    }

    function withdraw() public{
        require(now >= withdrawDate);
        require(msg.sender == theRichest);

         
        theRichest = 0;
        treasure = 0;

         
        owner.transfer(this.balance/100);
        
         
        msg.sender.transfer(this.balance);
    }

	 
	function kill() public
	{
		require(msg.sender==owner);
	        require(now >= withdrawDate);
		owner.transfer(this.balance/100);
		suicide(theRichest);
	}
}