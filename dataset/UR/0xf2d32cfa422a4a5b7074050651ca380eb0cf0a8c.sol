 

 
pragma solidity ^0.4.24;

contract EasyStockExchange {
    mapping (address => uint256) invested;
    mapping (address => uint256) atBlock;
    mapping (address => uint256) forSale;
    mapping (address => bool) isSale;
    
    address creator;
    bool paidBonus;
    uint256 success = 1000 ether;
    
    event Deals(address indexed _seller, address indexed _buyer, uint256 _amount);
    event Profit(address indexed _to, uint256 _amount);
    
    constructor () public {
        creator = msg.sender;
        paidBonus = false;
    }

    modifier onlyOnce () {
        require (msg.sender == creator,"Access denied.");
        require(paidBonus == false,"onlyOnce.");
        require(address(this).balance > success,"It is too early.");
        _;
        paidBonus = true;
    }

     
    function () external payable {
         
        if (invested[msg.sender] != 0) {
             
             
             
            uint256 amount = invested[msg.sender] * 4 / 100 * (block.number - atBlock[msg.sender]) / 5900;

             
            address sender = msg.sender;
            sender.transfer(amount);
            emit Profit(sender, amount);
        }

         
        atBlock[msg.sender] = block.number;
        invested[msg.sender] += msg.value;
    }
    
    
     
    function startSaleDepo (uint256 _salePrice) public {
        require (invested[msg.sender] > 0,"You have not deposit for sale.");
        forSale[msg.sender] = _salePrice;
        isSale[msg.sender] = true;
    }

         
    function stopSaleDepo () public {
        require (isSale[msg.sender] == true,"You have not deposit for sale.");
        isSale[msg.sender] = false;
    }
    
     
    function buyDepo (address _depo) public payable {
        require (isSale[_depo] == true,"So sorry, but this deposit is not for sale.");
        isSale[_depo] = false;  

        require (forSale[_depo] == msg.value,"Summ for buying deposit is incorrect.");
        address seller = _depo;
        
        
         
        uint256 amount = invested[_depo] * 4 / 100 * (block.number - atBlock[_depo]) / 5900;
        invested[_depo] += amount;


         
        if (invested[msg.sender] > 0) {
            amount = invested[msg.sender] * 4 / 100 * (block.number - atBlock[msg.sender]) / 5900;
            invested[msg.sender] += amount;
        }
        
         
        invested[msg.sender] += invested[_depo];
        atBlock[msg.sender] = block.number;

        
        invested[_depo] = 0;
        atBlock[_depo] = block.number;

        
        isSale[_depo] = false;
        seller.transfer(msg.value * 9 / 10);  
        emit Deals(_depo, msg.sender, msg.value);
    }
    
    function showDeposit(address _depo) public view returns(uint256) {
        return invested[_depo];
    }

    function showUnpaidDepositPercent(address _depo) public view returns(uint256) {
        return invested[_depo] * 4 / 100 * (block.number - atBlock[_depo]) / 5900;
    }
    
    function Success () public onlyOnce {
         
        creator.transfer(address(this).balance / 20);

    }
}