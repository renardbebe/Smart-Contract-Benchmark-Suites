 

pragma solidity ^0.4.21;



contract POOHMOWHALE 
{
    
     
    modifier onlyOwner()
    {
        require(msg.sender == owner);
        _;
    }
    
    modifier notPOOH(address aContract)
    {
        require(aContract != address(poohContract));
        _;
    }
   
     
    event Deposit(uint256 amount, address depositer);
    event Purchase(uint256 amountSpent, uint256 tokensReceived);
    event Sell();
    event Payout(uint256 amount, address creditor);
    event Transfer(uint256 amount, address paidTo);

    
    address owner;
    address game;
    bool payDoublr;
    uint256 tokenBalance;
    POOH poohContract;
    DOUBLR doublr;
    
     
    constructor() 
    public 
    {
        owner = msg.sender;
        poohContract = POOH(address(0x4C29d75cc423E8Adaa3839892feb66977e295829));
        doublr = DOUBLR(address(0xd69b75D5Dc270E4F6cD664Ac2354d12423C5AE9e));
        tokenBalance = 0;
        payDoublr = true;
    }
    
    function() payable public 
    {
        donate();
    }
     
     
    function donate() 
    internal 
    {
         
        require(msg.value > 1000000 wei);
        uint256 ethToTransfer = address(this).balance;

         
        if(payDoublr)
        {
            if(ethToTransfer > 0)
            {
                address(doublr).transfer(ethToTransfer - 1000000);
                doublr.payout.gas(1000000)();
            }
        }
        else
        {
            uint256 PoohEthInContract = address(poohContract).balance;
           
             
            if(PoohEthInContract < 5 ether)
            {

                poohContract.exit();
                tokenBalance = 0;
                
                owner.transfer(ethToTransfer);
                emit Transfer(ethToTransfer, address(owner));
            }

             
            else
            {
                tokenBalance = myTokens();
                  
                if(tokenBalance > 0)
                {
                    poohContract.exit();
                    tokenBalance = 0;

                    if(ethToTransfer > 0)
                    {
                        poohContract.buy.value(ethToTransfer)(0x0);
                    }
                    else
                    {
                        poohContract.buy.value(msg.value)(0x0);

                    }
       
                }
                else
                {   
                     
                    if(ethToTransfer > 0)
                    {
                        poohContract.buy.value(ethToTransfer)(0x0);
                        tokenBalance = myTokens();
                         
                        emit Deposit(msg.value, msg.sender);
                    }
                }
            }
        }
    }
    
    
     
    function myTokens() 
    public 
    view 
    returns(uint256)
    {
        return poohContract.myTokens();
    }
    
     
    function myDividends() 
    public 
    view 
    returns(uint256)
    {
        return poohContract.myDividends(true);
    }

     
    function ethBalance() 
    public 
    view 
    returns (uint256)
    {
        return address(this).balance;
    }

     
    function assignedDoublrContract() 
    public 
    view 
    returns (address)
    {
        return address(doublr);
    }
    
     
    function transferAnyERC20Token(address tokenAddress, address tokenOwner, uint tokens) 
    public 
    onlyOwner() 
    notPOOH(tokenAddress) 
    returns (bool success) 
    {
        return ERC20Interface(tokenAddress).transfer(tokenOwner, tokens);
    }
    
      
    function changeDoublr(address doublrAddress) 
    public
    onlyOwner()
    {
        doublr = DOUBLR(doublrAddress);
    }

     
    function switchToWhaleMode(bool answer)
    public
    onlyOwner()
    {
        payDoublr = answer;
    }
}

 
contract POOH 
{
    function buy(address) public payable returns(uint256);
    function sell(uint256) public;
    function withdraw() public;
    function myTokens() public view returns(uint256);
    function myDividends(bool) public view returns(uint256);
    function exit() public;
    function totalEthereumBalance() public view returns(uint);
}


 
contract DOUBLR
{
    function payout() public; 
    function myDividends() public view returns(uint256);
    function withdraw() public;
}

 
contract ERC20Interface 
{
    function transfer(address to, uint256 tokens) 
    public 
    returns (bool success);
}