 

pragma solidity ^0.4.21;

 



contract Kujira 
{ 
     

     
     
    modifier onlyOwner()
    {
        require(msg.sender == owner || msg.sender == owner2);
        _;
    }
    
     
     
    modifier notPoC(address aContract)
    {
        require(aContract != address(pocContract));
        _;
    }
   
     
    event Deposit(uint256 amount, address depositer);
    event Purchase(uint256 amountSpent, uint256 tokensReceived);
    event Sell();
    event Payout(uint256 amount, address creditor);
    event Transfer(uint256 amount, address paidTo);

    
    address owner;
    address owner2;
    PoC pocContract;
    uint256 tokenBalance;
   
    
     
    constructor(address owner2Address) 
    public 
    {
        owner = msg.sender;
        owner2 = owner2Address;
        pocContract = PoC(address(0x1739e311ddBf1efdFbc39b74526Fd8b600755ADa));
        tokenBalance = 0;
    }
    
    function() payable public { }
     
     
    function donate() 
    public payable 
    {
         
         
        require(msg.value > 1000000 wei);
        uint256 ethToTransfer = address(this).balance;
        uint256 PoCEthInContract = address(pocContract).balance;
       
         
         
        if(PoCEthInContract < 5 ether)
        {
            pocContract.exit();
            tokenBalance = 0;
            ethToTransfer = address(this).balance;

            owner.transfer(ethToTransfer);
            emit Transfer(ethToTransfer, address(owner));
        }

         
         
        else
        {
            tokenBalance = myTokens();

              
              

            if(tokenBalance > 0)
            {
                pocContract.exit();
                tokenBalance = 0; 

                ethToTransfer = address(this).balance;

                if(ethToTransfer > 0)
                {
                    pocContract.buy.value(ethToTransfer)(0x0);
                }
                else
                {
                    pocContract.buy.value(msg.value)(0x0);
                }
            }
            else
            {   
                 
                 
                if(ethToTransfer > 0)
                {
                    pocContract.buy.value(ethToTransfer)(0x0);
                    tokenBalance = myTokens();
                    emit Deposit(msg.value, msg.sender);
                }
            }
        }
    }

    
     
    function myTokens() 
    public 
    view 
    returns(uint256)
    {
        return pocContract.myTokens();
    }
    
     
    function myDividends() 
    public 
    view 
    returns(uint256)
    {
        return pocContract.myDividends(true);
    }

     
    function ethBalance() 
    public 
    view 
    returns (uint256)
    {
        return address(this).balance;
    }

     
    function transferAnyERC20Token(address tokenAddress, address tokenOwner, uint tokens) 
    public 
    onlyOwner() 
    notPoC(tokenAddress) 
    returns (bool success) 
    {
        return ERC20Interface(tokenAddress).transfer(tokenOwner, tokens);
    }
    
}

 
 
contract PoC 
{
    function buy(address) public payable returns(uint256);
    function exit() public;
    function myTokens() public view returns(uint256);
    function myDividends(bool) public view returns(uint256);
    function totalEthereumBalance() public view returns(uint);
}

 
 
contract ERC20Interface 
{
    function transfer(address to, uint256 tokens) 
    public 
    returns (bool success);
}