 

pragma solidity ^0.5.12;

 
contract NEST_3_OfferData {

    mapping (address => bool) addressMapping;        
    NEST_2_Mapping mappingContract;                  
    
     
    constructor(address map) public{
        mappingContract = NEST_2_Mapping(map);                                                      
    }
    
     
    function changeMapping(address map) public onlyOwner {
        mappingContract = NEST_2_Mapping(map);                                                    
    }
    
     
    function checkContract(address contractAddress) public view returns (bool){
        require(contractAddress != address(0x0));
        return addressMapping[contractAddress];
    }
    
     
    function addContractAddress(address contractAddress) public {
        require(address(mappingContract.checkAddress("offerFactory")) == msg.sender);
        addressMapping[contractAddress] = true;
    }
    
    modifier onlyOwner(){
        require(mappingContract.checkOwners(msg.sender) == true);
        _;
    }
}

 
contract NEST_3_OfferFactory {
    using SafeMath for uint256;
    using address_make_payable for address;
    mapping(address => bool) tokenAllow;                 
    NEST_2_Mapping mappingContract;                      
    NEST_3_OfferData dataContract;                       
    NEST_2_OfferPrice offerPrice;                        
    NEST_3_OrePoolLogic orePoolLogic;                    
    NEST_NodeAssignment NNcontract;                      
    ERC20 nestToken;                                     
    address abonusAddress;                               
    address coderAddress;                                
    uint256 miningETH = 10;                              
    uint256 tranEth = 2;                                 
    uint256 blockLimit = 25;                             
    uint256 tranAddition = 2;                            
    uint256 coderAmount = 5;                             
    uint256 NNAmount = 15;                               
    uint256 otherAmount = 80;                            
    uint256 leastEth = 1 ether;                          
    uint256 offerSpan = 1 ether;                         
    
     
    event offerTokenContractAddress(address contractAddress);    
     
    event offerContractAddress(address contractAddress, address tokenAddress, uint256 ethAmount, uint256 erc20Amount); 
     
    event offerTran(address tranSender, address tranToken, uint256 tranAmount,address otherToken, uint256 otherAmount, address tradedContract, address tradedOwner);        
    
     
    constructor (address map) public {
        mappingContract = NEST_2_Mapping(map);                                                      
        offerPrice = NEST_2_OfferPrice(address(mappingContract.checkAddress("offerPrice")));        
        orePoolLogic = NEST_3_OrePoolLogic(address(mappingContract.checkAddress("miningCalculation")));
        abonusAddress = mappingContract.checkAddress("abonus");
        nestToken = ERC20(mappingContract.checkAddress("nest"));                                        
        NNcontract = NEST_NodeAssignment(address(mappingContract.checkAddress("nodeAssignment")));      
        coderAddress = mappingContract.checkAddress("coder");
        dataContract = NEST_3_OfferData(address(mappingContract.checkAddress("offerData")));
    }
    
     
    function changeMapping(address map) public onlyOwner {
        mappingContract = NEST_2_Mapping(map);                                                          
        offerPrice = NEST_2_OfferPrice(address(mappingContract.checkAddress("offerPrice")));            
        orePoolLogic = NEST_3_OrePoolLogic(address(mappingContract.checkAddress("miningCalculation")));
        abonusAddress = mappingContract.checkAddress("abonus");
        nestToken = ERC20(mappingContract.checkAddress("nest"));                                         
        NNcontract = NEST_NodeAssignment(address(mappingContract.checkAddress("nodeAssignment")));      
        coderAddress = mappingContract.checkAddress("coder");
        dataContract = NEST_3_OfferData(address(mappingContract.checkAddress("offerData")));
    }
    
     
    function offer(uint256 ethAmount, uint256 erc20Amount, address erc20Address) public payable {
        require(address(msg.sender) == address(tx.origin));
        uint256 ethMining = ethAmount.mul(miningETH).div(1000);
        require(msg.value == ethAmount.add(ethMining));
        require(tokenAllow[erc20Address]);
        createOffer(ethAmount,erc20Amount,erc20Address,ethMining);
        orePoolLogic.oreDrawing.value(ethMining)(erc20Address);
    }
    
     
    function createOffer(uint256 ethAmount, uint256 erc20Amount, address erc20Address, uint256 mining) private {
        require(ethAmount >= leastEth);
        require(ethAmount % offerSpan == 0);
        require(erc20Amount % (ethAmount.div(offerSpan)) == 0);
        ERC20 token = ERC20(erc20Address);
        require(token.balanceOf(address(msg.sender)) >= erc20Amount);
        require(token.allowance(address(msg.sender), address(this)) >= erc20Amount);
        NEST_3_OfferContract newContract = new NEST_3_OfferContract(ethAmount,erc20Amount,erc20Address,mining,address(mappingContract));
        dataContract.addContractAddress(address(newContract));
        emit offerContractAddress(address(newContract), address(erc20Address), ethAmount, erc20Amount);
        token.transferFrom(address(msg.sender), address(newContract), erc20Amount);
        newContract.offerAssets.value(ethAmount)();
        offerPrice.addPrice(ethAmount,erc20Amount,erc20Address);
    }
    
     
    function turnOut(address contractAddress) public {
        require(address(msg.sender) == address(tx.origin));
        require(dataContract.checkContract(contractAddress));
        NEST_3_OfferContract offerContract = NEST_3_OfferContract(contractAddress);
        offerContract.turnOut();
        uint256 miningEth = offerContract.checkServiceCharge();
        uint256 blockNum = offerContract.checkBlockNum();
        address tokenAddress = offerContract.checkTokenAddress();
        if (miningEth > 0) {
            uint256 miningAmount = orePoolLogic.mining(miningEth, blockNum, address(this),tokenAddress);
            uint256 coder = miningAmount.mul(coderAmount).div(100);
            uint256 NN = miningAmount.mul(NNAmount).div(100);
            uint256 other = miningAmount.mul(otherAmount).div(100);
            nestToken.transfer(address(tx.origin), other);
            require(nestToken.approve(address(NNcontract), NN));
            NNcontract.bookKeeping(NN);                                               
            nestToken.transfer(coderAddress, coder);
        }
    }
    
     
    function ethTran(uint256 ethAmount, uint256 tokenAmount, address contractAddress, uint256 tranEthAmount, uint256 tranTokenAmount, address tranTokenAddress) public payable {
        require(address(msg.sender) == address(tx.origin));
        require(dataContract.checkContract(contractAddress));
        require(ethAmount >= tranEthAmount.mul(tranAddition));
        uint256 serviceCharge = tranEthAmount.mul(tranEth).div(1000);
        require(msg.value == ethAmount.add(tranEthAmount).add(serviceCharge));
        require(tranEthAmount % offerSpan == 0);
        createOffer(ethAmount,tokenAmount,tranTokenAddress,0);
        NEST_3_OfferContract offerContract = NEST_3_OfferContract(contractAddress);
        offerContract.changeOfferEth.value(tranEthAmount)(tranTokenAmount, tranTokenAddress);
        offerPrice.changePrice(tranEthAmount,tranTokenAmount,tranTokenAddress,offerContract.checkBlockNum());
        emit offerTran(address(tx.origin), address(0x0), tranEthAmount,address(tranTokenAddress),tranTokenAmount,contractAddress,offerContract.checkOwner());
        repayEth(abonusAddress,serviceCharge);
    }
    
     
    function ercTran(uint256 ethAmount, uint256 tokenAmount, address contractAddress, uint256 tranEthAmount, uint256 tranTokenAmount, address tranTokenAddress) public payable {
        require(address(msg.sender) == address(tx.origin));
        require(dataContract.checkContract(contractAddress));
        require(ethAmount >= tranEthAmount.mul(tranAddition));
        uint256 serviceCharge = tranEthAmount.mul(tranEth).div(1000);
        require(msg.value == ethAmount.add(serviceCharge));
        require(tranEthAmount % offerSpan == 0);
        createOffer(ethAmount,tokenAmount,tranTokenAddress,0);
        NEST_3_OfferContract offerContract = NEST_3_OfferContract(contractAddress);
        ERC20 token = ERC20(tranTokenAddress);
        require(token.balanceOf(address(msg.sender)) >= tranTokenAmount);
        require(token.allowance(address(msg.sender), address(this)) >= tranTokenAmount);
        token.transferFrom(address(msg.sender), address(offerContract), tranTokenAmount);
        offerContract.changeOfferErc(tranEthAmount,tranTokenAmount, tranTokenAddress);
        offerPrice.changePrice(tranEthAmount,tranTokenAmount,tranTokenAddress,offerContract.checkBlockNum());
        emit offerTran(address(tx.origin),address(tranTokenAddress),tranTokenAmount, address(0x0), tranEthAmount,contractAddress,offerContract.checkOwner());
        repayEth(abonusAddress,serviceCharge);
    }
    
    function repayEth(address accountAddress, uint256 asset) private {
        address payable addr = accountAddress.make_payable();
        addr.transfer(asset);
    }

     
    function checkBlockLimit() public view returns(uint256) {
        return blockLimit;
    }

     
    function checkMiningETH() public view returns (uint256) {
        return miningETH;
    }

     
    function checkTranEth() public view returns (uint256) {
        return tranEth;
    }

     
    function checkTokenAllow(address token) public view returns(bool) {
        return tokenAllow[token];
    }

     
    function checkTranAddition() public view returns(uint256) {
        return tranAddition;
    }

     
    function checkCoderAmount() public view returns(uint256) {
        return coderAmount;
    }

     
    function checkNNAmount() public view returns(uint256) {
        return NNAmount;
    }

     
    function checkOtherAmount() public view returns(uint256) {
        return otherAmount;
    }

     
    function checkleastEth() public view returns(uint256) {
        return leastEth;
    }

     
    function checkOfferSpan() public view returns(uint256) {
        return offerSpan;
    }

    function changeMiningETH(uint256 num) public onlyOwner {
        miningETH = num;
    }

    function changeTranEth(uint256 num) public onlyOwner {
        tranEth = num;
    }

    function changeBlockLimit(uint256 num) public onlyOwner {
        blockLimit = num;
    }

    function changeTokenAllow(address token, bool allow) public onlyOwner {
        tokenAllow[token] = allow;
    }

    function changeTranAddition(uint256 num) public onlyOwner {
        require(num > 0);
        tranAddition = num;
    }

    function changeInitialRatio(uint256 coderNum, uint256 NNNum, uint256 otherNum) public onlyOwner {
        require(coderNum > 0 && coderNum <= 5);
        require(NNNum > 0 && coderNum <= 15);
        require(coderNum.add(NNNum).add(otherNum) == 100);
        coderAmount = coderNum;
        NNAmount = NNNum;
        otherAmount = otherNum;
    }

    function changeLeastEth(uint256 num) public onlyOwner {
        require(num > 0);
        leastEth = num;
    }

    function changeOfferSpan(uint256 num) public onlyOwner {
        require(num > 0);
        offerSpan = num;
    }

    modifier onlyOwner(){
        require(mappingContract.checkOwners(msg.sender) == true);
        _;
    }
}


 
contract NEST_3_OfferContract {
    using SafeMath for uint256;
    using address_make_payable for address;
    address owner;                               
    uint256 ethAmount;                           
    uint256 tokenAmount;                         
    address tokenAddress;                        
    uint256 dealEthAmount;                       
    uint256 dealTokenAmount;                     
    uint256 blockNum;                            
    uint256 serviceCharge;                       
    bool hadReceive = false;                     
    NEST_2_Mapping mappingContract;              
    NEST_3_OfferFactory offerFactory;            
    
     
    constructor (uint256 _ethAmount, uint256 _tokenAmount, address _tokenAddress, uint256 miningEth,address map) public {
        mappingContract = NEST_2_Mapping(address(map));
        offerFactory = NEST_3_OfferFactory(address(mappingContract.checkAddress("offerFactory")));
        require(msg.sender == address(offerFactory));
        owner = address(tx.origin);
        ethAmount = _ethAmount;
        tokenAmount = _tokenAmount;
        tokenAddress = _tokenAddress;
        dealEthAmount = _ethAmount;
        dealTokenAmount = _tokenAmount;
        serviceCharge = miningEth;
        blockNum = block.number;
    }
    
    function offerAssets() public payable onlyFactory {
        require(ERC20(tokenAddress).balanceOf(address(this)) == tokenAmount);
    }
    
    function changeOfferEth(uint256 _tokenAmount, address _tokenAddress) public payable onlyFactory {
       require(checkContractState() == 0);
       require(dealEthAmount >= msg.value);
       require(dealTokenAmount >= _tokenAmount);
       require(_tokenAddress == tokenAddress);
       require(_tokenAmount == dealTokenAmount.mul(msg.value).div(dealEthAmount));
       ERC20(tokenAddress).transfer(address(tx.origin), _tokenAmount);
       dealEthAmount = dealEthAmount.sub(msg.value);
       dealTokenAmount = dealTokenAmount.sub(_tokenAmount);
    }
    
    function changeOfferErc(uint256 _ethAmount, uint256 _tokenAmount, address _tokenAddress) public onlyFactory {
       require(checkContractState() == 0);
       require(dealEthAmount >= _ethAmount);
       require(dealTokenAmount >= _tokenAmount);
       require(_tokenAddress == tokenAddress);
       require(_tokenAmount == dealTokenAmount.mul(_ethAmount).div(dealEthAmount));
       repayEth(address(tx.origin), _ethAmount);
       dealEthAmount = dealEthAmount.sub(_ethAmount);
       dealTokenAmount = dealTokenAmount.sub(_tokenAmount);
    }
   
    function repayEth(address accountAddress, uint256 asset) private {
        address payable addr = accountAddress.make_payable();
        addr.transfer(asset);
    }

    function turnOut() public onlyFactory {
        require(address(tx.origin) == owner);
        require(checkContractState() == 1);
        require(hadReceive == false);
        uint256 ethAssets;
        uint256 tokenAssets;
        (ethAssets, tokenAssets,) = checkAssets();
        repayEth(owner, ethAssets);
        ERC20(address(tokenAddress)).transfer(owner, tokenAssets);
        hadReceive = true;
    }
    
    function checkContractState() public view returns (uint256) {
        if (block.number.sub(blockNum) > offerFactory.checkBlockLimit()) {
            return 1;
        }
        return 0;
    }

    function checkDealAmount() public view returns(uint256 leftEth, uint256 leftErc20, address erc20Address) {
        return (dealEthAmount, dealTokenAmount, tokenAddress);
    }

    function checkPrice() public view returns(uint256 _ethAmount, uint256 _tokenAmount, address _tokenAddress) {
        return (ethAmount, tokenAmount, tokenAddress);
    }

    function checkAssets() public view returns(uint256 _ethAmount, uint256 _tokenAmount, address _tokenAddress) {
        return (address(this).balance, ERC20(address(tokenAddress)).balanceOf(address(this)), address(tokenAddress));
    }

    function checkTokenAddress() public view returns(address){
        return tokenAddress;
    }

    function checkOwner() public view returns(address) {
        return owner;
    }

    function checkBlockNum() public view returns (uint256) {
        return blockNum;
    }

    function checkServiceCharge() public view returns(uint256) {
        return serviceCharge;
    }

    function checkHadReceive() public view returns(bool) {
        return hadReceive;
    }
    
    modifier onlyFactory(){
        require(msg.sender == address(offerFactory));
        _;
    }
}


 
contract NEST_2_OfferPrice{
    using SafeMath for uint256;
    using address_make_payable for address;
    NEST_2_Mapping mappingContract;                                  
    NEST_3_OfferFactory offerFactory;                                
    struct Price {                                                   
        uint256 ethAmount;                                           
        uint256 erc20Amount;                                         
        uint256 blockNum;                                            
    }
    struct addressPrice {                                            
        mapping(uint256 => Price) tokenPrice;                        
        Price latestPrice;                                           
    }
    mapping(address => addressPrice) tokenInfo;                      
    uint256 priceCost = 0.01 ether;                                  
    uint256 priceCostUser = 2;                                       
    uint256 priceCostAbonus = 8;                                     
    mapping(uint256 => mapping(address => address)) blockAddress;    
    address abonusAddress;                                           
    
     
    event nowTokenPrice(address a, uint256 b, uint256 c);

     
    constructor (address map) public {
        mappingContract = NEST_2_Mapping(address(map));
        offerFactory = NEST_3_OfferFactory(address(mappingContract.checkAddress("offerFactory")));
        abonusAddress = address(mappingContract.checkAddress("abonus"));
    }
    
     
    function changeMapping(address map) public onlyOwner {
        mappingContract = NEST_2_Mapping(map);                                                      
        offerFactory = NEST_3_OfferFactory(address(mappingContract.checkAddress("offerFactory")));
        abonusAddress = address(mappingContract.checkAddress("abonus"));
    }
    
     
    function addPrice(uint256 _ethAmount, uint256 _tokenAmount, address _tokenAddress) public onlyFactory {
        uint256 blockLimit = offerFactory.checkBlockLimit();                                        
        uint256 middleBlock = block.number.sub(blockLimit);                                         
        
        uint256 priceBlock = tokenInfo[_tokenAddress].latestPrice.blockNum;                         
        while(priceBlock >= middleBlock || tokenInfo[_tokenAddress].tokenPrice[priceBlock].ethAmount == 0){                         
            priceBlock = tokenInfo[_tokenAddress].tokenPrice[priceBlock].blockNum;
            if (priceBlock == 0) {
                break;
            }
        }
        tokenInfo[_tokenAddress].latestPrice.ethAmount = tokenInfo[_tokenAddress].tokenPrice[priceBlock].ethAmount;
        tokenInfo[_tokenAddress].latestPrice.erc20Amount = tokenInfo[_tokenAddress].tokenPrice[priceBlock].erc20Amount;
        tokenInfo[_tokenAddress].tokenPrice[block.number].ethAmount = tokenInfo[_tokenAddress].tokenPrice[block.number].ethAmount.add(_ethAmount);                   
        tokenInfo[_tokenAddress].tokenPrice[block.number].erc20Amount = tokenInfo[_tokenAddress].tokenPrice[block.number].erc20Amount.add(_tokenAmount);             
        if (tokenInfo[_tokenAddress].latestPrice.blockNum != block.number) {
            tokenInfo[_tokenAddress].tokenPrice[block.number].blockNum = tokenInfo[_tokenAddress].latestPrice.blockNum;                                                  
            tokenInfo[_tokenAddress].latestPrice.blockNum = block.number;                                                                                                
        }

        blockAddress[block.number][_tokenAddress] = address(tx.origin);
        
        emit nowTokenPrice(_tokenAddress,tokenInfo[_tokenAddress].latestPrice.ethAmount, tokenInfo[_tokenAddress].latestPrice.erc20Amount);
    }
    
     
    function updateAndCheckPriceNow(address _tokenAddress) public payable returns(uint256 ethAmount, uint256 erc20Amount, address token) {
        if (msg.sender != tx.origin && msg.sender != address(offerFactory)) {
            require(msg.value == priceCost);
        }
        uint256 blockLimit = offerFactory.checkBlockLimit();                                       
        uint256 middleBlock = block.number.sub(blockLimit);                                   
        
        uint256 priceBlock = tokenInfo[_tokenAddress].latestPrice.blockNum;                     
        while(priceBlock >= middleBlock || tokenInfo[_tokenAddress].tokenPrice[priceBlock].ethAmount == 0){                         
            priceBlock = tokenInfo[_tokenAddress].tokenPrice[priceBlock].blockNum;
            if (priceBlock == 0) {
                break;
            }
        }
        tokenInfo[_tokenAddress].latestPrice.ethAmount = tokenInfo[_tokenAddress].tokenPrice[priceBlock].ethAmount;
        tokenInfo[_tokenAddress].latestPrice.erc20Amount = tokenInfo[_tokenAddress].tokenPrice[priceBlock].erc20Amount;
        if (msg.value > 0) {
            repayEth(abonusAddress, msg.value.mul(priceCostAbonus).div(10));
            repayEth(blockAddress[priceBlock][_tokenAddress], msg.value.mul(priceCostUser).div(10));
        }
        return (tokenInfo[_tokenAddress].latestPrice.ethAmount,tokenInfo[_tokenAddress].latestPrice.erc20Amount, _tokenAddress);
    }
    
    function repayEth(address accountAddress, uint256 asset) private {
        address payable addr = accountAddress.make_payable();
        addr.transfer(asset);
    }
    
     
    function changePrice(uint256 _ethAmount, uint256 _tokenAmount, address _tokenAddress, uint256 blockNum) public onlyFactory {
        tokenInfo[_tokenAddress].tokenPrice[blockNum].ethAmount = tokenInfo[_tokenAddress].tokenPrice[blockNum].ethAmount.sub(_ethAmount);
        tokenInfo[_tokenAddress].tokenPrice[blockNum].erc20Amount = tokenInfo[_tokenAddress].tokenPrice[blockNum].erc20Amount.sub(_tokenAmount);
    }
    
    function checkPriceForBlock(address tokenAddress, uint256 blockNum) public view returns (uint256 ethAmount, uint256 erc20Amount, uint256 frontBlock) {
        require(msg.sender == tx.origin);
        return (tokenInfo[tokenAddress].tokenPrice[blockNum].ethAmount, tokenInfo[tokenAddress].tokenPrice[blockNum].erc20Amount,tokenInfo[tokenAddress].tokenPrice[blockNum].blockNum);
    }    

    function checkPriceNow(address tokenAddress) public view returns (uint256 ethAmount, uint256 erc20Amount,uint256 frontBlock) {
        require(msg.sender == tx.origin);
        return (tokenInfo[tokenAddress].latestPrice.ethAmount,tokenInfo[tokenAddress].latestPrice.erc20Amount,tokenInfo[tokenAddress].latestPrice.blockNum);
    }

    function checkPriceHistoricalAverage(address tokenAddress, uint256 blockNum) public view returns (uint256) {
        require(msg.sender == tx.origin);
        uint256 blockLimit = offerFactory.checkBlockLimit();                                       
        uint256 middleBlock = block.number.sub(blockLimit);                                         
        uint256 priceBlock = tokenInfo[tokenAddress].latestPrice.blockNum;                         
        while(priceBlock >= middleBlock){                         
            priceBlock = tokenInfo[tokenAddress].tokenPrice[priceBlock].blockNum;
            if (priceBlock == 0) {
                break;
            }
        }
        uint256 frontBlock = priceBlock;
        uint256 price = 0;
        uint256 priceTimes = 0;
        while(frontBlock >= blockNum){   
            uint256 erc20Amount = tokenInfo[tokenAddress].tokenPrice[frontBlock].erc20Amount;
            uint256 ethAmount = tokenInfo[tokenAddress].tokenPrice[frontBlock].ethAmount;
            price = price.add(erc20Amount.mul(1 ether).div(ethAmount));
            priceTimes = priceTimes.add(1);
            frontBlock = tokenInfo[tokenAddress].tokenPrice[frontBlock].blockNum;
            if (frontBlock == 0) {
                break;
            }
        }
        return price.div(priceTimes);
    }
    
    function checkPriceForBlockPay(address tokenAddress, uint256 blockNum) public payable returns (uint256 ethAmount, uint256 erc20Amount, uint256 frontBlock) {
        require(msg.value == priceCost);
        require(tokenInfo[tokenAddress].tokenPrice[blockNum].ethAmount != 0);
        repayEth(abonusAddress, msg.value.mul(priceCostAbonus).div(10));
        repayEth(blockAddress[blockNum][tokenAddress], msg.value.mul(priceCostUser).div(10));
        return (tokenInfo[tokenAddress].tokenPrice[blockNum].ethAmount, tokenInfo[tokenAddress].tokenPrice[blockNum].erc20Amount,tokenInfo[tokenAddress].tokenPrice[blockNum].blockNum);
    }
    
    function checkPriceHistoricalAveragePay(address tokenAddress, uint256 blockNum) public payable returns (uint256) {
        require(msg.value == priceCost);
        uint256 blockLimit = offerFactory.checkBlockLimit();                                        
        uint256 middleBlock = block.number.sub(blockLimit);                                         
        uint256 priceBlock = tokenInfo[tokenAddress].latestPrice.blockNum;                          
        while(priceBlock >= middleBlock){                         
            priceBlock = tokenInfo[tokenAddress].tokenPrice[priceBlock].blockNum;
            if (priceBlock == 0) {
                break;
            }
        }
        repayEth(abonusAddress, msg.value.mul(priceCostAbonus).div(10));
        repayEth(blockAddress[priceBlock][tokenAddress], msg.value.mul(priceCostUser).div(10));
        uint256 frontBlock = priceBlock;
        uint256 price = 0;
        uint256 priceTimes = 0;
        while(frontBlock >= blockNum){   
            uint256 erc20Amount = tokenInfo[tokenAddress].tokenPrice[frontBlock].erc20Amount;
            uint256 ethAmount = tokenInfo[tokenAddress].tokenPrice[frontBlock].ethAmount;
            price = price.add(erc20Amount.mul(1 ether).div(ethAmount));
            priceTimes = priceTimes.add(1);
            frontBlock = tokenInfo[tokenAddress].tokenPrice[frontBlock].blockNum;
            if (frontBlock == 0) {
                break;
            }
        }
        return price.div(priceTimes);
    }

    
    function checkLatestBlock(address token) public view returns(uint256) {
        return tokenInfo[token].latestPrice.blockNum;
    }
    
    function changePriceCost(uint256 amount) public onlyOwner {
        require(amount > 0);
        priceCost = amount;
    }
     
    function checkPriceCost() public view returns(uint256) {
        return priceCost;
    }
    
    function changePriceCostProportion(uint256 user, uint256 abonus) public onlyOwner {
        require(user.add(abonus) == 10);
        priceCostUser = user;
        priceCostAbonus = abonus;
    }
    
    function checkPriceCostProportion() public view returns(uint256 user, uint256 abonus) {
        return (priceCostUser, priceCostAbonus);
    }
    
    modifier onlyFactory(){
        require(msg.sender == address(mappingContract.checkAddress("offerFactory")));
        _;
    }
    
    modifier onlyOwner(){
        require(mappingContract.checkOwners(msg.sender) == true);
        _;
    }
}

contract NEST_NodeAssignment {
    function bookKeeping(uint256 amount) public;
}

contract NEST_3_OrePoolLogic {
    function oreDrawing(address token) public payable;
    function mining(uint256 amount, uint256 blockNum, address target, address token) public returns(uint256);
}

contract NEST_2_Mapping {
    function checkAddress(string memory name) public view returns (address contractAddress);
    function checkOwners(address man) public view returns (bool);
}

library address_make_payable {
   function make_payable(address x) internal pure returns (address payable) {
      return address(uint160(x));
   }
}

contract ERC20 {
    function totalSupply() public view returns (uint supply);
    function balanceOf( address who ) public view returns (uint value);
    function allowance( address owner, address spender ) public view returns (uint _allowance);

    function transfer( address to, uint256 value) external;
    function transferFrom( address from, address to, uint value) public;
    function approve( address spender, uint value ) public returns (bool ok);

    event Transfer( address indexed from, address indexed to, uint value);
    event Approval( address indexed owner, address indexed spender, uint value);
}

 
library SafeMath {
    int256 constant private INT256_MIN = -2**255;

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}