 

pragma solidity ^0.4.19;


contract SafeMath {
    function safeMul(uint256 a, uint256 b) internal returns (uint256) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal returns (uint256) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }

     
     
     
}


 
 
contract ERC20Interface {
     
    function totalSupply() public constant returns (uint256 totalSupply);

     
    function balanceOf(address _owner) public constant returns (uint256 balance);

     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract Etx is ERC20Interface {
    uint256 public expirationBlock;
    function isActive(address _owner) public returns (bool activated);
}


contract Ethex is SafeMath {
    address public admin;  
    address public feeAccount;  
    address public etxAddress;

    uint256 public makeFee;  
    uint256 public takeFee;  
    uint256 public lastFreeBlock;

    mapping (bytes32 => uint256) public sellOrderBalances;  
    mapping (bytes32 => uint256) public buyOrderBalances;  

    event MakeBuyOrder(bytes32 orderHash, address indexed token, uint256 tokenAmount, uint256 weiAmount, address indexed buyer);

    event MakeSellOrder(bytes32 orderHash, address indexed token, uint256 tokenAmount, uint256 weiAmount, address indexed seller);

    event CancelBuyOrder(bytes32 orderHash, address indexed token, uint256 tokenAmount, uint256 weiAmount, address indexed buyer);

    event CancelSellOrder(bytes32 orderHash, address indexed token, uint256 tokenAmount, uint256 weiAmount, address indexed seller);

    event TakeBuyOrder(bytes32 orderHash, address indexed token, uint256 tokenAmount, uint256 weiAmount, uint256 totalTransactionTokens, address indexed buyer, address indexed seller);

    event TakeSellOrder(bytes32 orderHash, address indexed token, uint256 tokenAmount, uint256 weiAmount, uint256 totalTransactionWei, address indexed buyer, address indexed seller);

    function Ethex(address admin_, address feeAccount_, uint256 makeFee_, uint256 takeFee_, address etxAddress_, uint256 _lastFreeBlock) public {
        admin = admin_;
        feeAccount = feeAccount_;
        makeFee = makeFee_;
        takeFee = takeFee_;
        etxAddress = etxAddress_;
        lastFreeBlock = _lastFreeBlock;
    }

    function() public {
        revert();
    }

    function changeAdmin(address admin_) public {
        require(msg.sender == admin);
        admin = admin_;
    }

    function changeETXAddress(address etxAddress_) public {
        require(msg.sender == admin);
        require(block.number > Etx(etxAddress).expirationBlock());
        etxAddress = etxAddress_;
    }

    function changeLastFreeBlock(uint256 _lastFreeBlock) public {
        require(msg.sender == admin);
        require(_lastFreeBlock > block.number + 100);  
        lastFreeBlock = _lastFreeBlock;
    }

    function changeFeeAccount(address feeAccount_) public {
        require(msg.sender == admin);
        feeAccount = feeAccount_;
    }

    function changeMakeFee(uint256 makeFee_) public {
        require(msg.sender == admin);
        require(makeFee_ < makeFee);
        makeFee = makeFee_;
    }

    function changeTakeFee(uint256 takeFee_) public {
        require(msg.sender == admin);
        require(takeFee_ < takeFee);
        takeFee = takeFee_;
    }

    function feeFromTotalCostForAccount(uint256 totalCost, uint256 feeAmount, address account) public constant returns (uint256) {
        if (Etx(etxAddress).isActive(account)) {
             
            return 0;
        }

        if (block.number <= lastFreeBlock)
        {
            return 0;
        }

        return feeFromTotalCost(totalCost, feeAmount);
    }

    function feeFromTotalCost(uint256 totalCost, uint256 feeAmount) public constant returns (uint256) {

        uint256 cost = safeMul(totalCost, (1 ether)) / safeAdd((1 ether), feeAmount);

         
        uint256 remainder = safeMul(totalCost, (1 ether)) % safeAdd((1 ether), feeAmount);
        if (remainder != 0) {
            cost = safeAdd(cost, 1);
        }

        uint256 fee = safeSub(totalCost, cost);
        return fee;
    }

    function calculateFeeForAccount(uint256 cost, uint256 feeAmount, address account) public constant returns (uint256) {
        if (Etx(etxAddress).isActive(account)) {
             
            return 0;
        }

        if (block.number <= lastFreeBlock)
        {
            return 0;
        }

        return calculateFee(cost, feeAmount);
    }

    function calculateFee(uint256 cost, uint256 feeAmount) public constant returns (uint256) {

        uint256 fee = safeMul(cost, feeAmount) / (1 ether);
        return fee;
    }

     
    function makeSellOrder(address token, uint256 tokenAmount, uint256 weiAmount) public {
        require(tokenAmount != 0);
        require(weiAmount != 0);

        bytes32 h = sha256(token, tokenAmount, weiAmount, msg.sender);


         
        sellOrderBalances[h] = safeAdd(sellOrderBalances[h], tokenAmount);

         
        require(tokenAmount <= ERC20Interface(token).allowance(msg.sender, this));

         
        if (!ERC20Interface(token).transferFrom(msg.sender, this, tokenAmount)) {
            revert();
        }


        MakeSellOrder(h, token, tokenAmount, weiAmount, msg.sender);
    }

     
    function makeBuyOrder(address token, uint256 tokenAmount) public payable {
        require(tokenAmount != 0);
        require(msg.value != 0);

        uint256 fee = feeFromTotalCost(msg.value, makeFee);
        uint256 valueNoFee = safeSub(msg.value, fee);
        bytes32 h = sha256(token, tokenAmount, valueNoFee, msg.sender);

         
        buyOrderBalances[h] = safeAdd(buyOrderBalances[h], msg.value);

         
        MakeBuyOrder(h, token, tokenAmount, valueNoFee, msg.sender);
    }


     
    function cancelAllSellOrders(address token, uint256 tokenAmount, uint256 weiAmount) public {
        bytes32 h = sha256(token, tokenAmount, weiAmount, msg.sender);
        uint256 remain = sellOrderBalances[h];
        delete sellOrderBalances[h];

        ERC20Interface(token).transfer(msg.sender, remain);

        CancelSellOrder(h, token, tokenAmount, weiAmount, msg.sender);
    }

     
    function cancelAllBuyOrders(address token, uint256 tokenAmount, uint256 weiAmount) public {
        bytes32 h = sha256(token, tokenAmount, weiAmount, msg.sender);
        uint256 remain = buyOrderBalances[h];
        delete buyOrderBalances[h];

        if (!msg.sender.send(remain)) {
            revert();
        }

        CancelBuyOrder(h, token, tokenAmount, weiAmount, msg.sender);
    }

     
    function takeBuyOrder(address token, uint256 tokenAmount, uint256 weiAmount, uint256 totalTokens, address buyer) public {
        require(tokenAmount != 0);
        require(weiAmount != 0);
        require(totalTokens != 0);

        bytes32 h = sha256(token, tokenAmount, weiAmount, buyer);

         
        uint256 transactionWeiAmountNoFee = safeMul(totalTokens, weiAmount) / tokenAmount;

         
        uint256 unvestedMakeFee = calculateFee(transactionWeiAmountNoFee, makeFee);
        uint256 totalTransactionWeiAmount = safeAdd(transactionWeiAmountNoFee, unvestedMakeFee);
        require(buyOrderBalances[h] >= totalTransactionWeiAmount);


         
        uint256 currentTakeFee = calculateFeeForAccount(transactionWeiAmountNoFee, takeFee, msg.sender);
        uint256 currentMakeFee = calculateFeeForAccount(transactionWeiAmountNoFee, makeFee, buyer);

         

         
        buyOrderBalances[h] = safeSub(buyOrderBalances[h], totalTransactionWeiAmount);


         
        require(ERC20Interface(token).allowance(msg.sender, this) >= totalTokens);

         
        if (currentMakeFee < unvestedMakeFee) { 
            uint256 refundAmount = safeSub(unvestedMakeFee, currentMakeFee);
            if (!buyer.send(refundAmount)) {
                revert();
            }
        }
        if (!ERC20Interface(token).transferFrom(msg.sender, buyer, totalTokens)) {
            revert();
        }

         
        if (safeAdd(currentTakeFee, currentMakeFee) > 0) {
            if (!feeAccount.send(safeAdd(currentTakeFee, currentMakeFee))) {
                revert();
            }
        }

         
        if (!msg.sender.send(safeSub(transactionWeiAmountNoFee, currentTakeFee))) {
            revert();
        }

        TakeBuyOrder(h, token, tokenAmount, weiAmount, totalTokens, buyer, msg.sender);
    }


    function takeSellOrder(address token, uint256 tokenAmount, uint256 weiAmount, address seller) public payable {

        require(tokenAmount != 0);
        require(weiAmount != 0);

        bytes32 h = sha256(token, tokenAmount, weiAmount, seller);

         
        uint256 currentTakeFee = feeFromTotalCostForAccount(msg.value, takeFee, msg.sender);
        uint256 transactionWeiAmountNoFee = safeSub(msg.value, currentTakeFee);
        uint256 totalTokens = safeMul(transactionWeiAmountNoFee, tokenAmount) / weiAmount;
        require(sellOrderBalances[h] >= totalTokens);

         
        uint256 currentMakeFee = calculateFeeForAccount(transactionWeiAmountNoFee, makeFee, seller);
        uint256 totalFee = safeAdd(currentMakeFee, currentTakeFee);

        uint256 makerProceedsAfterFee = safeSub(transactionWeiAmountNoFee, currentMakeFee);

         

         
        sellOrderBalances[h] = safeSub(sellOrderBalances[h], totalTokens);

         
        if (!ERC20Interface(token).transfer(msg.sender, totalTokens)) {
            revert();
        }

         
        if (totalFee > 0) {
            if (!feeAccount.send(totalFee)) {
                revert();
            }
        }

         
        if (!seller.send(makerProceedsAfterFee)) {
            revert();
        }

        TakeSellOrder(h, token, tokenAmount, weiAmount, transactionWeiAmountNoFee, msg.sender, seller);
    }
}