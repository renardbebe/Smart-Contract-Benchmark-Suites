 

pragma solidity ^0.5.0;


library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

}

contract Ownable {

    using SafeMath for *;
    uint ethWei = 1 ether;

    address public owner;
    address public manager;
    address public ownerWallet;

    constructor() public {
        owner = msg.sender;
        manager = msg.sender;
        ownerWallet = 0xC28a057CA181e6fa84bbC22F5f0372B3B13A500f;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only for owner");
        _;
    }

    modifier onlyOwnerOrManager() {
        require((msg.sender == owner)||(msg.sender == manager), "only for owner or manager");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    function setManager(address _manager) public onlyOwnerOrManager {
        manager = _manager;
    }
}

contract SRulesUtils {

    uint256 ethWei = 1 ether;

    function strCompare(string memory _str, string memory str) internal pure returns (bool) {
        
        if (keccak256(abi.encodePacked(_str)) == keccak256(abi.encodePacked(str))) {
            return true;
        }
        return false;
    }

    function divider(uint numerator, uint denominator, uint precision) internal pure returns(uint) {
        return numerator*(uint(10)**uint(precision))/denominator;
    }
}

contract SRules is SRulesUtils,Ownable {

    event reEntryEvent(uint _clientID,address indexed _client,address _referrer, uint256 _amount, uint256 _time,uint _portfolioId);
    event rebateReport(uint[] clientReport,uint[] rebateBonusReport,uint[] bvReport, uint prevRebatePercent);
    event goldmineReport(uint[] fromClient,uint[] clientAry,uint[] fromLvl,uint[] bonusPercentAry,uint[] bvAmtAry,uint[] payAmtAry);
    event rankingReport(uint[] clientAry, uint[] fromClient, uint[] bonusPercentAry);
    event updateReentryEvent(address indexed _client, uint256 _amount, uint256 _time,uint _portfolioId);
    event payoutReport(uint wallet, address[] addrAry,uint256[] payoutArray);
    struct Client {
        bool isExist;
        uint id;
        address addr;
        uint referrerID;
        string status;
        uint256 createdOn;
        string inviteCode;
    }

    mapping (address => Client) public clients;
    mapping (uint => address) private clientList;
    uint private currClientID = 10000;
    uint private ownerID = 0;

    mapping(string => address) private codeMapping;

    struct TreeSponsor {
        uint clientID;
        uint uplineID;
        uint level;
    }
    mapping (uint => TreeSponsor) public treeSponsors;
    mapping (uint => uint[] ) public sponsorDownlines;

    struct Portfolio {
        uint id;
        uint clientID;
        uint256 amount;
        uint256 bonusValue;
        uint256 withdrawAmt;
         
         
        string status;
        uint256 createdOn;
        uint256 updatedOn;
    }
    mapping (uint => Portfolio) public portfolios;
    mapping (uint => uint[]) private clientPortfolios;
    mapping (uint => uint256) public clientBV;
    mapping (uint => uint256) public cacheClientBV;
    mapping (uint => uint256) public rebate2Client;

    uint private clientBonusCount = 0;
    uint private portfolioID = 0;
    uint256 private minReentryValue = 1 * ethWei;
    uint256 private maxReentryValue = 500 * ethWei;


    struct WalletDetail {
        uint percentage;
        address payable toWallet;
    }
    mapping (uint => WalletDetail) public walletDetails;
    uint private walletDetailsCount = 0;
    mapping (uint => uint256) public poolBalance;
    address payable defaultGasAddr = 0x0B6593C16CecC4407FE9f4727ceE367327EF4779;

    struct WithdrawalDetail {
        uint minDay;
        uint charges;
    }
    mapping (uint => WithdrawalDetail) public withdrawalDetails;

    struct RebateSetting{
        uint max;
        uint min;
        uint percent;
    }
    mapping (uint => RebateSetting) public rebateSettings;
    uint private rebateSettingsCount = 0;
    uint public rebateDisplay = 0.33 * 100;

    uint private prevRebatePercent = 0;
    uint public defaultRebatePercent = 0.33 * 100;
    uint public defaultRebateDays = 21;
    uint public rebateDays = 1;
    uint public lowestRebateFlag = 0;

    mapping (uint => uint) public clientGoldmine;
    mapping (uint => uint) public goldmineSettingsPer;
    mapping (uint => uint) public goldmineDownlineSet;

    uint private maxGoldmineLevel = 50;

    uint256 public totalSales = 0;
    uint256 public totalPayout = 0;

    uint256 public cacheTotalSales = 0;
    uint256 public cacheTotalPayout = 0;

    modifier isHuman() {
        require(msg.sender == tx.origin, "sorry humans only - FOR REAL THIS TIME");
        _;
    }

    function() external payable {
    }

    constructor() public {

         
        walletDetailsCount++;
        walletDetails[walletDetailsCount] = WalletDetail({
            percentage : 70 * 100,
            toWallet : address(0)
        });
        
         
        walletDetailsCount++;
        walletDetails[walletDetailsCount] = WalletDetail({
            percentage : 2 * 100,
            toWallet : address(0)
        });
        
         
        walletDetailsCount++;
        walletDetails[walletDetailsCount] = WalletDetail({
            percentage : 5 * 100,
            toWallet : address(0)
        });
        
         
        walletDetailsCount++;
        walletDetails[walletDetailsCount] = WalletDetail({
            percentage : 1 * 100,
            toWallet : defaultGasAddr
        });
        
         
        walletDetailsCount++;
        walletDetails[walletDetailsCount] = WalletDetail({
            percentage : 3.5 * 100,
            toWallet : 0x40568dfb53726E3341dE75E04310C570B183D614
        });
        
         
        walletDetailsCount++;
        walletDetails[walletDetailsCount] = WalletDetail({
            percentage : 15 * 100,
            toWallet : 0x5076E5a092FDB2d456787bfa870390a72Ae51BF9
        });

         
        walletDetailsCount++;
        walletDetails[walletDetailsCount] = WalletDetail({
            percentage : 3.5 * 100,
            toWallet : 0x05649CDE4c22f77b73Df306CA7057951c3cC0e21
        });

         
         
        withdrawalDetails[1] = WithdrawalDetail({
            minDay : 0,
            charges : 5 * 100
        });

         
        withdrawalDetails[2] = WithdrawalDetail({
            minDay : 30,
            charges : 1 * 100
        });


        rebateSettingsCount++;
        rebateSettings[rebateSettingsCount] = RebateSetting({
            max : 69.99 * 100,
            min : 61.34 * 100,
            percent : 0.1 * 100
            });

        rebateSettingsCount++;
        rebateSettings[rebateSettingsCount] = RebateSetting({
            max : 61.33 * 100,
            min : 59.23 * 100,
            percent : 0.2 * 100
            });

        rebateSettingsCount++;
        rebateSettings[rebateSettingsCount] = RebateSetting({
            max : 59.22 * 100,
            min : 57.11 * 100,
            percent : 0.3 * 100
            });

        rebateSettingsCount++;
        rebateSettings[rebateSettingsCount] = RebateSetting({
            max : 57.1 * 100,
            min : 55 * 100,
            percent : 0.4 * 100
            });

        rebateSettingsCount++;
        rebateSettings[rebateSettingsCount] = RebateSetting({
            max : 54.99 * 100,
            min : 52.88 * 100,
            percent : 0.5 * 100
            });

        rebateSettingsCount++;
        rebateSettings[rebateSettingsCount] = RebateSetting({
            max : 52.87 * 100,
            min : 50.77 * 100,
            percent : 0.6 * 100
            });

        rebateSettingsCount++;
        rebateSettings[rebateSettingsCount] = RebateSetting({
            max : 50.76 * 100,
            min : 48.65 * 100,
            percent : 0.7 * 100
            });

        rebateSettingsCount++;
        rebateSettings[rebateSettingsCount] = RebateSetting({
            max : 48.64 * 100,
            min : 46.54 * 100,
            percent : 0.8 * 100
            });

        rebateSettingsCount++;
        rebateSettings[rebateSettingsCount] = RebateSetting({
            max : 46.53 * 100,
            min : 44.42 * 100,
            percent : 0.9 * 100
            });

        rebateSettingsCount++;
        rebateSettings[rebateSettingsCount] = RebateSetting({
            max : 44.41 * 100,
            min : 42.31 * 100,
            percent : 1.0 * 100
            });

        rebateSettingsCount++;
        rebateSettings[rebateSettingsCount] = RebateSetting({
            max : 42.3 * 100,
            min : 40.19 * 100,
            percent : 1.1 * 100
            });

        rebateSettingsCount++;
        rebateSettings[rebateSettingsCount] = RebateSetting({
            max : 40.18 * 100,
            min : 38.08 * 100,
            percent : 1.2 * 100
            });

        rebateSettingsCount++;
        rebateSettings[rebateSettingsCount] = RebateSetting({
            max : 38.07 * 100,
            min : 35.96 * 100,
            percent : 1.3 * 100
            });

        rebateSettingsCount++;
        rebateSettings[rebateSettingsCount] = RebateSetting({
            max : 35.95 * 100,
            min : 33.85 * 100,
            percent : 1.4 * 100
            });

        rebateSettingsCount++;
        rebateSettings[rebateSettingsCount] = RebateSetting({
            max : 33.84 * 100,
            min : 31.73 * 100,
            percent : 1.5 * 100
            });

        rebateSettingsCount++;
        rebateSettings[rebateSettingsCount] = RebateSetting({
            max : 31.72 * 100,
            min : 29.62 * 100,
            percent : 1.6 * 100
            });

        rebateSettingsCount++;
        rebateSettings[rebateSettingsCount] = RebateSetting({
            max : 29.61 * 100,
            min : 27.5 * 100,
            percent : 1.7 * 100
            });

        rebateSettingsCount++;
        rebateSettings[rebateSettingsCount] = RebateSetting({
            max : 27.49 * 100,
            min : 25.39 * 100,
            percent : 1.8 * 100
            });

        rebateSettingsCount++;
        rebateSettings[rebateSettingsCount] = RebateSetting({
            max : 25.38 * 100,
            min : 23.27 * 100,
            percent : 1.9 * 100
            });

        rebateSettingsCount++;
        rebateSettings[rebateSettingsCount] = RebateSetting({
            max : 23.26 * 100,
            min : 21.16 * 100,
            percent : 2.0 * 100
            });

        rebateSettingsCount++;
        rebateSettings[rebateSettingsCount] = RebateSetting({
            max : 21.15 * 100,
            min : 19.04 * 100,
            percent : 2.1 * 100
            });

        rebateSettingsCount++;
        rebateSettings[rebateSettingsCount] = RebateSetting({
            max : 19.03 * 100,
            min : 16.93 * 100,
            percent : 2.2 * 100
            });

        rebateSettingsCount++;
        rebateSettings[rebateSettingsCount] = RebateSetting({
            max : 16.92 * 100,
            min : 14.81 * 100,
            percent : 2.3 * 100
            });

        rebateSettingsCount++;
        rebateSettings[rebateSettingsCount] = RebateSetting({
            max : 14.8 * 100,
            min : 12.7 * 100,
            percent : 2.4 * 100
            });

        rebateSettingsCount++;
        rebateSettings[rebateSettingsCount] = RebateSetting({
            max : 12.69 * 100,
            min : 10.58 * 100,
            percent : 2.5 * 100
            });

        rebateSettingsCount++;
        rebateSettings[rebateSettingsCount] = RebateSetting({
            max : 10.57 * 100,
            min : 5.3 * 100,
            percent : 2.6 * 100
            });

        rebateSettingsCount++;
        rebateSettings[rebateSettingsCount] = RebateSetting({
            max : 5.29 * 100,
            min : 0 * 100,
            percent : 2.7 * 100
            });

        goldmineSettingsPer[0] = 0;
        goldmineDownlineSet[0] = 0;
        goldmineSettingsPer[1] = 100 * 100;
        goldmineDownlineSet[1] = 1;
        goldmineSettingsPer[2] = 50 * 100;
        goldmineDownlineSet[2] = 2;
        goldmineSettingsPer[3] = 5 * 100;
        goldmineDownlineSet[3] = 3;


        Client memory client;
        currClientID++;

        client = Client({
            isExist : true,
            id : currClientID,
            addr : ownerWallet,
            referrerID : 0,
            status : "Active",
            createdOn : now,
            inviteCode : ""
             
        });
        clients[ownerWallet] = client;
        clientList[currClientID] = ownerWallet;
        ownerID = currClientID;
        TreeSponsor memory sponsor;
        sponsor = TreeSponsor({
            clientID : currClientID,
            uplineID : 0,
            level : 0
        });
        treeSponsors[currClientID] = sponsor;

        for(uint i = 1; i <= walletDetailsCount;i++){
            if(walletDetails[i].toWallet == address(0)){
                poolBalance[i] = 0;
            }
        }

        poolBalance[4] = 0;
    }

    function regMember(address _refAddr) private{
        require(!clients[msg.sender].isExist, 'User exist');
        require(clients[_refAddr].isExist, 'Invalid upline address');
        require(strCompare(clients[_refAddr].status,"Active"), 'Invalid upline address');

        uint sponsorID = clients[_refAddr].id;

        Client memory client;
        currClientID++;

        client = Client({
            isExist : true,
            id : currClientID,
            addr : msg.sender,
            referrerID : sponsorID,
            status : "Pending",
            createdOn : now,
            inviteCode : ""
        });
        
        clients[msg.sender] = client;
        clientList[currClientID] = msg.sender;

         
        TreeSponsor memory sponsor;
        sponsor = TreeSponsor({
            clientID : currClientID,
            uplineID : sponsorID,
            level : treeSponsors[sponsorID].level +1
        });
        treeSponsors[currClientID] = sponsor;
        sponsorDownlines[sponsorID].push(currClientID);
        clientBV[currClientID] = 0;
    }

    function reEntry() public payable isHuman{
        reEntry('');
    }

    function reEntry (string memory _inviteCode) public payable isHuman{
        require(msg.value >= minReentryValue, "The amount is less than minimum reentry amount");
        address refAddr;
        if(clients[msg.sender].isExist == false){
            require(!strCompare(_inviteCode, ""), "invalid invite code");
            require(getInviteCode(_inviteCode), "Invite code not exist");
            refAddr = codeMapping[_inviteCode];
            require(refAddr != msg.sender, "Invite Code can't be self");
            regMember(refAddr);
        }
        
        uint clientID = clients[msg.sender].id;
        require((msg.value + clientBV[clientID]) <= maxReentryValue, "The amount is more than maximum reentry amount");
        Portfolio memory portfolio;

        portfolioID ++;

        portfolio = Portfolio({
            id : portfolioID,
            clientID : clientID,
            amount : msg.value,
            bonusValue : msg.value,
            withdrawAmt : 0,
            status : "Pending",
            createdOn : now,
            updatedOn : now
            });

        portfolios[portfolioID] = portfolio;
        clientPortfolios[clientID].push(portfolioID);
        
        emit reEntryEvent(clientID, msg.sender, refAddr, msg.value, now,portfolioID);
    }

    function updateReentryStatus(address _client, uint256 _amount, uint _portfolio,string calldata _inviteCode) external payable onlyOwnerOrManager{

        require(clients[_client].isExist, 'Invalid Member');
        uint clientID = clients[_client].id;

        require(strCompare(portfolios[_portfolio].status,"Pending"), 'Portfolio is not in pending status');
        require(portfolios[_portfolio].amount == _amount , 'The amount is not match with portfolio amount');
        require(portfolios[_portfolio].clientID == clientID, 'The portfolio is not belong to this member');
        
        if(strCompare(clients[_client].status,"Pending") == true){
            clients[_client].status = "Active";
            clients[_client].inviteCode = _inviteCode;
            
            codeMapping[_inviteCode] = _client;
        }

        portfolios[_portfolio].status = "Active";
        portfolios[_portfolio].updatedOn = now;

        clientBV[clientID] = clientBV[clientID].add(_amount);
        distSales(_amount);

        totalSales = totalSales.add(_amount);
         

        emit updateReentryEvent(_client, _amount, now,portfolioID);
    }

    function distSales (uint256 _amount) private {
        for(uint i = 1; i <= walletDetailsCount;i++){
            uint256 transferAmount = 0;
            transferAmount = _amount.mul(walletDetails[i].percentage).div(10000);
            if(transferAmount > 0){
                if(walletDetails[i].toWallet == address(0)){
                    poolBalance[i] = poolBalance[i].add(transferAmount);
                }else if(walletDetails[i].toWallet == defaultGasAddr){
                    walletDetails[i].toWallet.transfer(transferAmount);

                    poolBalance[i] = defaultGasAddr.balance;

                }else{
                    walletDetails[i].toWallet.transfer(transferAmount);
                }
            }
        }
    }
    
    

    function percentageDisplay() private {
        uint bonusPercent = 0;

        if(rebateDays <= defaultRebateDays){
         
            bonusPercent = defaultRebatePercent;
        }else{
            uint overall = divider(totalPayout,cacheTotalSales, 4);
            uint count = 1;
            while(count <= rebateSettingsCount){
                if(overall >= rebateSettings[count].min){
                    bonusPercent = rebateSettings[count].percent;
                    break;
                }

                count++;
            }
        }
        rebateDisplay = bonusPercent;
    }

     

    function getTodayBonus() external onlyOwnerOrManager returns (string memory) {

        cacheTotalSales = totalSales;
        cacheTotalPayout = totalPayout;

        uint bonusPercent = 0;
         
         
         
         
         
         
         
         
         
         
         

         
         
         
        bonusPercent = rebateDisplay;

        rebateDays++;

        if(bonusPercent == rebateSettings[1].percent){
            lowestRebateFlag ++;
        }else{
            lowestRebateFlag = 0;
        }
        prevRebatePercent = bonusPercent;


        return("successful");
    }

    function clientCache (uint start, uint end, uint[] calldata clientIDAry, uint[] calldata bonusValueAry) external onlyOwnerOrManager returns (string memory) {
        clientBonusCount = 0;
        uint i = 0;
        uint bonusValue = 0;
        for(uint clientID = start; clientID <= end;clientID++){
            if(clientIDAry[i] == clientID){
                bonusValue = bonusValueAry[i];
                i++;
            }else{
                bonusValue = 0;
            }

            cacheClientBV[clientID] = bonusValue;
            rebate2Client[clientID] = 0;
            clientBonusCount++;
        }

        return("successful");
    }

    function rebate (uint start, uint end) external onlyOwnerOrManager{
        require(clientBonusCount > 0, 'No bonus to count');

        uint[] memory rebateBonusReport= new uint[](100);
        uint[] memory bvReport= new uint[](100);
        uint[] memory clientReport = new uint[](100);

        uint j = 0;
        for(uint i = start; i <= end;i++){

            uint bvAmt = 0;
            uint payAmt = 0;

            bvAmt = cacheClientBV[i];
            if(bvAmt < minReentryValue) continue;

            payAmt = bvAmt.mul(prevRebatePercent).div(10000);
            if(payAmt > 0){
                rebate2Client[i] = payAmt;

                clientReport[j] = i;
                bvReport[j] = bvAmt;
                rebateBonusReport[j] = payAmt;
                j++;
            }
        }
        
        emit rebateReport(clientReport,rebateBonusReport,bvReport,prevRebatePercent);
    }

    function getGoldmineRank(uint start, uint end) external onlyOwnerOrManager returns (string memory){

        for(uint i = start; i <= end;i++){
            uint downlineCounts = 0;

            for(uint j = 0; j < sponsorDownlines[i].length;j++){
                if(cacheClientBV[sponsorDownlines[i][j]] >= minReentryValue){
                    downlineCounts += 1;
                }
            }
             
            if(downlineCounts > 3 ){
                downlineCounts = 3;
            }

            if(cacheClientBV[i] >= maxReentryValue){
                downlineCounts = 3;
            }else if(cacheClientBV[i] < minReentryValue){
                downlineCounts = 0;
            }

            clientGoldmine[i] = goldmineDownlineSet[downlineCounts];
        }
        return ("successful");
    }



    function goldmine(uint start, uint end) external onlyOwnerOrManager{

        uint[] memory fromClient = new uint[](250);
        uint[] memory clientAry = new uint[](250);
        uint[] memory bvAmtAry = new uint[](250);
        uint[] memory payAmtAry = new uint[](250);
        uint[] memory bonusPercentAry = new uint[](250);
        uint[] memory fromLvl = new uint[](250);

        uint k = 0;

        for(uint clientID = start ; clientID <= end;clientID++){

            if(rebate2Client[clientID] <= 0 ) continue;

            uint targetID = clientID;
            uint lvl = 1;

            while(lvl <= maxGoldmineLevel){
                uint payAmt = 0;
                uint bonusPercent = 0;
                uint frmLvl = lvl;
                uint uplineID = treeSponsors[targetID].uplineID;
                if(uplineID == 10001){
                    break;
                }
                
                targetID = uplineID;

                if(lvl <= clientGoldmine[uplineID]){
                    bonusPercent = goldmineSettingsPer[lvl];
                }else if(lvl > 3 && clientGoldmine[uplineID] == 3){
                    uint perLvl = 3;
                    bonusPercent = goldmineSettingsPer[perLvl];
                }else{
                    bonusPercent = 0;
                }
                
                lvl++;

                if(bonusPercent <= 0){
                    continue;
                }
                
                payAmt = rebate2Client[clientID].mul(bonusPercent).div(10000);

                if(payAmt > 0 ){
                    fromClient[k] = clientID;
                    clientAry[k] = targetID;
                    fromLvl[k] = frmLvl;
                    bonusPercentAry[k] = bonusPercent;
                    bvAmtAry[k] = rebate2Client[clientID];
                    payAmtAry[k] = payAmt;
                    k++;
                }
            }
        }

        emit goldmineReport(fromClient,clientAry,fromLvl,bonusPercentAry,bvAmtAry,payAmtAry);
    }

    function payPoolAmount(uint _wallet, address[] calldata _addrAry, uint[] calldata _amountAry) external payable onlyOwnerOrManager {
         
        require (_wallet > 0,"Invalid Wallet");
        require (poolBalance[_wallet] > 0,"Insufficent Pool Balance");
        require (_amountAry.length > 0,"Empty Amount");

        uint256[] memory payoutArray = new uint256[](_addrAry.length);

        for(uint i = 0; i < _addrAry.length; i++){
            payoutArray[i] = 0;

            if(!strCompare(clients[_addrAry[i]].status, "Active")){
                continue;
            }

            uint payAmt = _amountAry[i];

            if(poolBalance[_wallet] < _amountAry[i]){
                payAmt = poolBalance[_wallet];
            }

            if (poolBalance[_wallet] >= payAmt){
                address payable userAddr = address(uint160(_addrAry[i]));
                poolBalance[_wallet] = poolBalance[_wallet].sub(payAmt);
                
                if(_wallet == 1){
                    totalPayout = totalPayout.add(payAmt);
                    cacheTotalPayout = cacheTotalPayout.add(payAmt);
                }
                
                userAddr.transfer(payAmt);
                payoutArray[i] = payAmt;
            }
        }

        percentageDisplay();

        emit payoutReport(_wallet,_addrAry,payoutArray);
    }

    function withdrawal(uint portfolio) public payable isHuman{

        require (clients[msg.sender].isExist,"Invalid Member");
        require (strCompare(portfolios[portfolio].status, "Active"),"This portfolio is not active portfolio.");
        uint clientID = clients[msg.sender].id;
        require (portfolios[portfolio].clientID == clientID,"Invalid Portfolio");
        
        uint256 portAmt = portfolios[portfolio].bonusValue;
        uint chargesPercent = 0;
        if(now - portfolios[portfolio].updatedOn <= 30 days){
            chargesPercent = withdrawalDetails[1].charges;
        }else{
            chargesPercent = withdrawalDetails[2].charges;
        }

        uint256 adminCharges = portAmt.mul(chargesPercent).div(10000);

        uint256 withdrawalAmount = portAmt.sub(adminCharges);

        require (clientBV[clientID] >= withdrawalAmount,"Withdrawal Amount is bigger than BV Amount.");
        require (clientBV[clientID] >= portAmt,"Portfolio Amount is bigger than BV Amount.");
        
        if(withdrawalAmount > poolBalance[1]){
            withdrawalAmount = poolBalance[1];
        }

        require (poolBalance[1] >= withdrawalAmount,"Insufficent Pool Balance. Cannot Withdrawal.");

         
            portfolios[portfolio].status = "Terminated";
            portfolios[portfolio].withdrawAmt = withdrawalAmount;

            portfolios[portfolio].updatedOn = now;

            clientBV[clientID] = clientBV[clientID].sub(portAmt);
            poolBalance[1] = poolBalance[1].sub(withdrawalAmount);
            
            totalPayout = totalPayout.add(withdrawalAmount);
             

            msg.sender.transfer(withdrawalAmount);
         
    }

    function airDrop(address[] calldata _topFund,address[] calldata _topSponsor) external view returns (uint256,uint256){
        uint topFundLength = _topFund.length;
        uint topSponsorLength = _topSponsor.length;

         
        uint256 bonusAmount = poolBalance[2].div(2);

         
        uint256 bonusTopFund = bonusAmount.div(topFundLength);
        uint256 bonusTopSponsor = bonusAmount.div(topSponsorLength);

        return (bonusTopFund,bonusTopSponsor);
    }

    function ranking(uint[] calldata _clientIDAry, uint[] calldata _uplinesAry, uint[] calldata _rankAry, uint[] calldata _uplineNum) external{
         
        uint[] memory clientAry = new uint[](50);
        uint[] memory fromClient = new uint[](50);
        uint[] memory bonusPercentAry = new uint[](50);

        uint j = 0;

        for(uint client = 0; client < _clientIDAry.length; client++){
            uint downlinePercentage = 0;
            
            for(uint uplines = j; uplines < _uplineNum[client]; uplines++){
                uint curPercentage = _rankAry[uplines];
                if(curPercentage < downlinePercentage) {
                    curPercentage = downlinePercentage;
                }
    
                fromClient[j] = _clientIDAry[client];
                clientAry[j] = _uplinesAry[uplines];
                bonusPercentAry[j] = curPercentage.sub(downlinePercentage);
    
                downlinePercentage = curPercentage;
                j++;
            }
        }
        emit rankingReport(clientAry, fromClient, bonusPercentAry);
    }

    function checkReset() public view returns (string memory) {
        if(lowestRebateFlag >= 5){
            return "Reset";
        }else if(poolBalance[1] <= 0){
            return "Reset";
        }
        return "Nothing happen";
    }
    
    function reset() external payable onlyOwnerOrManager{
        string memory resettable=checkReset();
        require(strCompare(resettable,"Reset"), 'Cannot Reset'); 
        
        rebateDays = 1;
        prevRebatePercent = defaultRebatePercent;
        rebateDisplay = defaultRebatePercent;
        totalSales = 0;
        totalPayout = 0;
        cacheTotalSales = 0;
        cacheTotalPayout = 0;

        for(uint clientID = 10002; clientID <= currClientID;clientID++){
            clientBV[clientID] = 0;
        }

        for(uint portfolioId = 1; portfolioId <= portfolioID; portfolioId++){
            if(!strCompare(portfolios[portfolioId].status,"Active")){
                continue;
            }
            portfolios[portfolioId].status = "Flushed";
            portfolios[portfolioId].updatedOn = now;
        }

        if(poolBalance[1] > 0){
             
            walletDetails[6].toWallet.transfer(poolBalance[1]);
            poolBalance[1] = poolBalance[1].sub(poolBalance[1]);
        }

        if(poolBalance[2] > 0){
             
            walletDetails[6].toWallet.transfer(poolBalance[2]);
            poolBalance[2] = poolBalance[2].sub(poolBalance[2]);
        }
    }

    function payRecyclePool(uint[] calldata _addrAry, uint[] calldata _percentAry) external payable onlyOwnerOrManager{
        if(poolBalance[3] > 0){

            uint256 poolAmt = poolBalance[3];
             
            for(uint i = 0; i < _addrAry.length; i++){
                address payable userAddr = address(uint160(_addrAry[i]));
                if(_percentAry[i] > 0){
                    uint payAmt = poolAmt.mul(_percentAry[i]).div(10000);
                    if(poolBalance[3] >= payAmt){
                        userAddr.transfer(payAmt);
                        poolBalance[3] = poolBalance[3].sub(payAmt);
                    }
                }
            }  
        }
    }

    function getInviteCode(string memory _inviteCode) public view returns (bool) {
        address addr = codeMapping[_inviteCode];
        return uint(addr) != 0;
    }

    function updateInviteCode (address _clientAddress, string calldata _inviteCode) external onlyOwnerOrManager{
        require(clients[_clientAddress].isExist, 'Invalid member');
        clients[_clientAddress].inviteCode = _inviteCode;
        codeMapping[_inviteCode] = _clientAddress;
    }

    function clearPool (uint _wallet, uint _toWallet) external payable onlyOwnerOrManager{
        require (_wallet > 0,"Invalid Wallet");
        require (_toWallet > 0,"Invalid To Wallet");
        require (poolBalance[_wallet] > 0,"Insufficent Pool Balance");        
        if(poolBalance[_wallet] > 0){
            walletDetails[_toWallet].toWallet.transfer(poolBalance[_wallet]);
            poolBalance[_wallet] = poolBalance[_wallet].sub(poolBalance[_wallet]);
        }
    }

    function updateWallet(uint _wallet, address payable _updateAddress) external onlyOwnerOrManager{
        require (_wallet > 3,"Invalid Wallet");
        require (walletDetails[_wallet].toWallet != address(0),"Invalid Wallet");
        require (_updateAddress != address(0),"Invalid Wallet Address");

        walletDetails[_wallet].toWallet = _updateAddress;
    }
}