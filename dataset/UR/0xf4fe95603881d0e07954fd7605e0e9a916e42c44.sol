 

pragma solidity ^0.4.18;

 
 
 
 
 
contract WHENToken {
    using SafeMath for uint256;

    mapping(address => uint256) balances;                                
    mapping (address => mapping (address => uint256)) internal allowed;  

     
    string public name;
    string public symbol;
    uint public decimals = 18;
    string public sign = "￦";
    string public logoPng = "https://github.com/WhenHub/WHEN/raw/master/assets/when-token-icon.png";


     
    struct User {
        bool isRegistered;                                               
        uint256 seedJiffys;                                              
        uint256 interfaceEscrowJiffys;                                   
        address referrer;                                                
    }
 
     
    struct IcoBurnAuthorized {
        bool contractOwner;                                               
        bool platformManager;                                             
        bool icoOwner;                                                    
    }

     
    struct PurchaseCredit {
        uint256 jiffys;                                                   
        uint256 purchaseTimestamp;                                        
    }

    mapping(address => PurchaseCredit) purchaseCredits;                   

    uint private constant ONE_WEEK = 604800;
    uint private constant SECONDS_IN_MONTH = 2629743;
    uint256 private constant ICO_START_TIMESTAMP = 1521471600;  

    uint private constant BASIS_POINTS_TO_PERCENTAGE = 10000;                          

     
    uint private constant ICO_TOKENS = 350000000;                               
    uint private constant PLATFORM_TOKENS = 227500000;                          
    uint private constant COMPANY_TOKENS = 262500000;                           
    uint private constant PARTNER_TOKENS = 17500000;                            
    uint private constant FOUNDATION_TOKENS = 17500000;                         

     
    uint constant INCENTIVE_TOKENS = 150000000;                          
    uint constant REFERRAL_TOKENS = 77500000;                            
    uint256 private userSignupJiffys = 0;                                 
    uint256 private referralSignupJiffys = 0;                             
   
    uint256 private jiffysMultiplier;                                    
    uint256 private incentiveJiffysBalance;                              
    uint256 private referralJiffysBalance;                               

     
    uint256 private bonus20EndTimestamp = 0;                              
    uint256 private bonus10EndTimestamp = 0;                              
    uint256 private bonus5EndTimestamp = 0;                               
    uint private constant BUYER_REFERRER_BOUNTY = 3;                      

    IcoBurnAuthorized icoBurnAuthorized = IcoBurnAuthorized(false, false, false);

     
    bool private operational = true;                                     
                                                                         

    uint256 public winNetworkFeeBasisPoints = 0;                        
                                                                         

    uint256 public weiExchangeRate = 500000000000000;                   
                                                                         

    uint256 public centsExchangeRate = 25;                              
                                                                         

     
    address private contractOwner;                                       
    address private platformManager;                                     
    address private icoOwner;                                            
    address private supportManager;                                      
    address private icoWallet;                                           

    mapping(address => User) private users;                              
    mapping(address => uint256) private vestingEscrows;                  

    mapping(address => uint256) private authorizedContracts;             

    address[] private registeredUserLookup;                              

     
    event Approval           
                            (
                                address indexed owner, 
                                address indexed spender, 
                                uint256 value
                            );

    event Transfer           
                            (
                                address indexed from, 
                                address indexed to, 
                                uint256 value
                            );


     
    event UserRegister       
                            (
                                address indexed user, 
                                uint256 value,
                                uint256 seedJiffys
                            );                                 

    event UserRefer          
                            (
                                address indexed user, 
                                address indexed referrer, 
                                uint256 value
                            );                             

    event UserLink           
                            (
                                address indexed user
                            );


     
    modifier requireIsOperational() 
    {
        require(operational);
        _;
    }

     
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner);
        _;
    }

     
    modifier requirePlatformManager()
    {
        require(isPlatformManager(msg.sender));
        _;
    }


     
     
     

     
    function WHENToken
                            ( 
                                string tokenName, 
                                string tokenSymbol, 
                                address platformAccount, 
                                address icoAccount,
                                address supportAccount
                            ) 
                            public 
    {

        name = tokenName;
        symbol = tokenSymbol;

        jiffysMultiplier = 10 ** uint256(decimals);                              
        incentiveJiffysBalance = INCENTIVE_TOKENS.mul(jiffysMultiplier);         
        referralJiffysBalance = REFERRAL_TOKENS.mul(jiffysMultiplier);           


        contractOwner = msg.sender;                                      
        platformManager = platformAccount;                               
        icoOwner = icoAccount;                                           
        icoWallet = icoOwner;                                            
        supportManager = supportAccount;                                 

                
         
        users[contractOwner] = User(true, 0, 0, address(0));       
        registeredUserLookup.push(contractOwner);

        users[platformManager] = User(true, 0, 0, address(0));   
        registeredUserLookup.push(platformManager);

        users[icoOwner] = User(true, 0, 0, address(0));   
        registeredUserLookup.push(icoOwner);

        users[supportManager] = User(true, 0, 0, address(0));   
        registeredUserLookup.push(supportManager);

    }    

     
    function initialize
                            (
                                address dataContract,
                                address appContract,
                                address vestingContract
                            )
                            external
                            requireContractOwner
    {        
        require(bonus20EndTimestamp == 0);       
        authorizeContract(dataContract);         
        authorizeContract(appContract);          
        authorizeContract(vestingContract);      
        
        bonus20EndTimestamp = ICO_START_TIMESTAMP.add(ONE_WEEK);
        bonus10EndTimestamp = bonus20EndTimestamp.add(ONE_WEEK);
        bonus5EndTimestamp = bonus10EndTimestamp.add(ONE_WEEK);

         
        balances[icoOwner] = ICO_TOKENS.mul(jiffysMultiplier);        

         
        balances[platformManager] = balances[platformManager].add(PLATFORM_TOKENS.mul(jiffysMultiplier));        

         
         
        balances[contractOwner] = balances[contractOwner].add((COMPANY_TOKENS + PARTNER_TOKENS + FOUNDATION_TOKENS).mul(jiffysMultiplier));

        userSignupJiffys = jiffysMultiplier.mul(500);        
        referralSignupJiffys = jiffysMultiplier.mul(100);    
       
    }

     
    function getTokenAllocations()
                                external
                                view
                                returns(uint256, uint256, uint256)
    {
        return (COMPANY_TOKENS.mul(jiffysMultiplier), PARTNER_TOKENS.mul(jiffysMultiplier), FOUNDATION_TOKENS.mul(jiffysMultiplier));
    }

     
     
     

     
    function totalSupply() 
                            external 
                            view 
                            returns (uint) 
    {
        uint256 total = ICO_TOKENS.add(PLATFORM_TOKENS).add(COMPANY_TOKENS).add(PARTNER_TOKENS).add(FOUNDATION_TOKENS);
        return total.mul(jiffysMultiplier);
    }

     
    function balance()
                            public 
                            view 
                            returns (uint256) 
    {
        return balanceOf(msg.sender);
    }

     
    function balanceOf
                            (
                                address owner
                            ) 
                            public 
                            view 
                            returns (uint256) 
    {
        return balances[owner];
    }

     
    function transfer
                            (
                                address to, 
                                uint256 value
                            ) 
                            public 
                            requireIsOperational 
                            returns (bool) 
    {
        require(to != address(0));
        require(to != msg.sender);
        require(value <= transferableBalanceOf(msg.sender));                                         

        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        Transfer(msg.sender, to, value);
        return true;
    }

     
    function transferFrom
                            (
                                address from, 
                                address to, 
                                uint256 value
                            ) 
                            public 
                            requireIsOperational 
                            returns (bool) 
    {
        require(from != address(0));
        require(value <= allowed[from][msg.sender]);
        require(value <= transferableBalanceOf(from));                                         
        require(to != address(0));
        require(from != to);

        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        Transfer(from, to, value);
        return true;
    }

     
    function allowance
                            (
                                address owner, 
                                address spender
                            ) 
                            public 
                            view 
                            returns (uint256) 
    {
        return allowed[owner][spender];
    }

     
    function approve
                            (
                                address spender, 
                                uint256 value
                            ) 
                            public 
                            requireIsOperational 
                            returns (bool) 
    {
        allowed[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
        return true;
    }

     
    function transferableBalanceOf
                            (
                                address account
                            ) 
                            public 
                            view 
                            returns (uint256) 
    {
        require(account != address(0));

        if (users[account].isRegistered) {
            uint256 restrictedJiffys = users[account].interfaceEscrowJiffys >= users[account].seedJiffys ? users[account].interfaceEscrowJiffys : users[account].seedJiffys;
            return balances[account].sub(restrictedJiffys);
        }
        return balances[account];
    }

     
    function spendableBalanceOf
                            (
                                address account
                            ) 
                            public 
                            view 
                            returns(uint256) 
    {

        require(account != address(0));

        if (users[account].isRegistered) {
            return balances[account].sub(users[account].interfaceEscrowJiffys);
        }
        return balances[account];
    }

     
     
     


          
    function isOperational() 
                            public 
                            view 
                            returns(bool) 
    {
        return operational;
    }

        
    function setOperatingStatus
                            (
                                bool mode
                            ) 
                            external
                            requireContractOwner 
    {
        operational = mode;
    }

     
    function authorizeIcoBurn() 
                            external
    {
        require(balances[icoOwner] > 0);
        require((msg.sender == contractOwner) || (msg.sender == platformManager) || (msg.sender == icoOwner));

        if (msg.sender == contractOwner) {
            icoBurnAuthorized.contractOwner = true;
        } else if (msg.sender == platformManager) {
            icoBurnAuthorized.platformManager = true;
        } else if (msg.sender == icoOwner) {
            icoBurnAuthorized.icoOwner = true;
        }

        if (icoBurnAuthorized.contractOwner && icoBurnAuthorized.platformManager && icoBurnAuthorized.icoOwner) {
            balances[icoOwner] = 0;
        }
    }

        
    function setWinNetworkFee
                            (
                                uint256 basisPoints
                            ) 
                            external 
                            requireIsOperational 
                            requireContractOwner
    {
        require(basisPoints >= 0);

        winNetworkFeeBasisPoints = basisPoints;
    }

         
    function setUserSignupTokens
                            (
                                uint256 tokens
                            ) 
                            external 
                            requireIsOperational 
                            requireContractOwner
    {
        require(tokens <= 10000);

        userSignupJiffys = jiffysMultiplier.mul(tokens);
    }

         
    function setReferralSignupTokens
                            (
                                uint256 tokens
                            ) 
                            external 
                            requireIsOperational 
                            requireContractOwner
    {
        require(tokens <= 10000);

        referralSignupJiffys = jiffysMultiplier.mul(tokens);
    }

         
    function setIcoWallet
                            (
                                address account
                            ) 
                            external 
                            requireIsOperational 
                            requireContractOwner
    {
        require(account != address(0));

        icoWallet = account;
    }

     
    function authorizeContract
                            (
                                address account
                            ) 
                            public 
                            requireIsOperational 
                            requireContractOwner
    {
        require(account != address(0));

        authorizedContracts[account] = 1;
    }

     
    function deauthorizeContract
                            (
                                address account
                            ) 
                            external 
                            requireIsOperational
                            requireContractOwner 
    {
        require(account != address(0));

        delete authorizedContracts[account];
    }

     
    function isContractAuthorized
                            (
                                address account
                            ) 
                            public 
                            view
                            returns(bool) 
    {
        return authorizedContracts[account] == 1;
    }

     
    function setWeiExchangeRate
                            (
                                uint256 rate
                            ) 
                            external 
                            requireIsOperational
                            requireContractOwner
    {
        require(rate >= 0);  

        weiExchangeRate = rate;
    }

     
    function setCentsExchangeRate
                            (
                                uint256 rate
                            ) 
                            external 
                            requireIsOperational
                            requireContractOwner
    {
        require(rate >= 1);

        centsExchangeRate = rate;
    }

     
    function setPlatformManager
                            (
                                address account
                            ) 
                            external 
                            requireIsOperational
                            requireContractOwner
    {
        require(account != address(0));
        require(account != platformManager);

        balances[account] = balances[account].add(balances[platformManager]);
        balances[platformManager] = 0;

        if (!users[account].isRegistered) {
            users[account] = User(true, 0, 0, address(0)); 
            registeredUserLookup.push(account);
        }

        platformManager = account; 
    }

     
    function isPlatformManager
                            (
                                address account
                            ) 
                            public
                            view 
                            returns(bool) 
    {
        return account == platformManager;
    }

     
    function isPlatformOrSupportManager
                            (
                                address account
                            ) 
                            public
                            view 
                            returns(bool) 
    {
        return (account == platformManager) || (account == supportManager);
    }

     
    function getSupportManager()
                            public
                            view 
                            returns(address) 
    {
        return supportManager;
    }


         
    function isReferralSupported() 
                            public 
                            view 
                            returns(bool) 
    {
        uint256 requiredJiffys = referralSignupJiffys.mul(2);
        return (referralJiffysBalance >= requiredJiffys) && (balances[platformManager] >= requiredJiffys);
    }

     
    function isUserRegistered
                            (
                                address account
                            ) 
                            public 
                            view 
                            returns(bool) 
    {
        return (account != address(0)) && users[account].isRegistered;
    }

     
    function processRegisterUser
                            (
                                address account, 
                                address creditAccount,
                                address referrer
                            ) 
                            private
    {
        require(account != address(0));                                              
        require(!users[account].isRegistered);                                       
        require(referrer == address(0) ? true : users[referrer].isRegistered);       
        require(referrer != account);                                                

         
        users[account] = User(true, 0, 0, referrer);
        registeredUserLookup.push(account);


        if (purchaseCredits[creditAccount].jiffys > 0) {
            processPurchase(creditAccount, account, purchaseCredits[creditAccount].jiffys, purchaseCredits[creditAccount].purchaseTimestamp);
            purchaseCredits[creditAccount].jiffys = 0;
            delete purchaseCredits[creditAccount];
        }

    }

      
    function registerUser
                            (
                                address account, 
                                address creditAccount,
                                address referrer
                            ) 
                            public 
                            requireIsOperational 
                            requirePlatformManager 
                            returns(uint256) 
    {
                                    
        processRegisterUser(account, creditAccount, referrer);
        UserRegister(account, balanceOf(account), 0);           

        return balanceOf(account);
    }

     
    function registerUserBonus
                            (
                                address account, 
                                address creditAccount,
                                address referrer
                            ) 
                            external 
                            requireIsOperational 
                            requirePlatformManager 
                            returns(uint256) 
    {
        
        processRegisterUser(account, creditAccount, referrer);

        
         
        uint256 jiffys = 0;
        if ((incentiveJiffysBalance >= userSignupJiffys) && (balances[platformManager] >= userSignupJiffys)) {
            incentiveJiffysBalance = incentiveJiffysBalance.sub(userSignupJiffys);
            users[account].seedJiffys = users[account].seedJiffys.add(userSignupJiffys);
            transfer(account, userSignupJiffys);
            jiffys = userSignupJiffys;
        }

        UserRegister(account, balanceOf(account), jiffys);           

        
       if ((referrer != address(0)) && isReferralSupported()) {
            referralJiffysBalance = referralJiffysBalance.sub(referralSignupJiffys.mul(2));

             
            transfer(referrer, referralSignupJiffys);
            users[referrer].seedJiffys = users[referrer].seedJiffys.add(referralSignupJiffys);

            transfer(account, referralSignupJiffys);
            users[account].seedJiffys = users[account].seedJiffys.add(referralSignupJiffys);

            UserRefer(account, referrer, referralSignupJiffys);      
        }

        return balanceOf(account);
    }

      
    function depositEscrow
                            (
                                address account, 
                                uint256 jiffys
                            ) 
                            external 
                            requireIsOperational 
    {
        if (jiffys > 0) {
            require(isContractAuthorized(msg.sender) || isPlatformManager(msg.sender));   
            require(isUserRegistered(account));                                                     
            require(spendableBalanceOf(account) >= jiffys);

            users[account].interfaceEscrowJiffys = users[account].interfaceEscrowJiffys.add(jiffys);
        }
    }

      
    function refundEscrow
                            (
                                address account, 
                                uint256 jiffys
                            ) 
                            external 
                            requireIsOperational 
    {
        if (jiffys > 0) {
            require(isContractAuthorized(msg.sender) || isPlatformManager(msg.sender));   
            require(isUserRegistered(account));                                                     
            require(users[account].interfaceEscrowJiffys >= jiffys);

            users[account].interfaceEscrowJiffys = users[account].interfaceEscrowJiffys.sub(jiffys);
        }
    }

      
    function pay
                            (
                                address payer, 
                                address payee, 
                                address referrer, 
                                uint256 referralFeeBasisPoints, 
                                uint256 billableJiffys,
                                uint256 escrowJiffys
                            ) 
                            external 
                            requireIsOperational 
                            returns(uint256, uint256)
    {
        require(isContractAuthorized(msg.sender));   
        require(billableJiffys >= 0);
        require(users[payer].interfaceEscrowJiffys >= billableJiffys);   
        require(users[payee].isRegistered);

         
         
         
         
         
         


         
        users[payer].interfaceEscrowJiffys = users[payer].interfaceEscrowJiffys.sub(escrowJiffys);
        uint256 referralFeeJiffys = 0;
        uint256 winNetworkFeeJiffys = 0;

        if (billableJiffys > 0) {

             
            processPayment(payer, payee, billableJiffys);

             
            if (payee != supportManager) {

                 
                if ((referralFeeBasisPoints > 0) && (referrer != address(0)) && (users[referrer].isRegistered)) {
                    referralFeeJiffys = billableJiffys.mul(referralFeeBasisPoints).div(BASIS_POINTS_TO_PERCENTAGE);  
                    processPayment(payee, referrer, referralFeeJiffys);
                }

                 
                if (winNetworkFeeBasisPoints > 0) {
                    winNetworkFeeJiffys = billableJiffys.mul(winNetworkFeeBasisPoints).div(BASIS_POINTS_TO_PERCENTAGE);  
                    processPayment(payee, contractOwner, winNetworkFeeJiffys);
                }                    
            }
        }

        return(referralFeeJiffys, winNetworkFeeJiffys);
    }
    
          
    function processPayment
                               (
                                   address payer,
                                   address payee,
                                   uint256 jiffys
                               )
                               private
    {
        require(isUserRegistered(payer));
        require(isUserRegistered(payee));
        require(spendableBalanceOf(payer) >= jiffys);

        balances[payer] = balances[payer].sub(jiffys); 
        balances[payee] = balances[payee].add(jiffys);
        Transfer(payer, payee, jiffys);

         
         
         
         
         
         
        if (users[payer].seedJiffys >= jiffys) {
            users[payer].seedJiffys = users[payer].seedJiffys.sub(jiffys);
        } else {
            users[payer].seedJiffys = 0;
        }
           
    }

          
    function vestingGrant
                            (
                                address issuer, 
                                address beneficiary, 
                                uint256 vestedJiffys,
                                uint256 unvestedJiffys
                            ) 
                            external 
                            requireIsOperational 
    {
        require(isContractAuthorized(msg.sender));   
        require(spendableBalanceOf(issuer) >= unvestedJiffys.add(vestedJiffys));


         
        if (vestedJiffys > 0) {
            balances[issuer] = balances[issuer].sub(vestedJiffys);
            balances[beneficiary] = balances[beneficiary].add(vestedJiffys);
            Transfer(issuer, beneficiary, vestedJiffys);
        }

         
         
         
        balances[issuer] = balances[issuer].sub(unvestedJiffys);
        vestingEscrows[issuer] = vestingEscrows[issuer].add(unvestedJiffys);
    }


          
    function vestingTransfer
                            (
                                address issuer, 
                                address beneficiary, 
                                uint256 jiffys
                            ) 
                            external 
                            requireIsOperational 
    {
        require(isContractAuthorized(msg.sender));   
        require(vestingEscrows[issuer] >= jiffys);

        vestingEscrows[issuer] = vestingEscrows[issuer].sub(jiffys);
        balances[beneficiary] = balances[beneficiary].add(jiffys);
        Transfer(issuer, beneficiary, jiffys);
    }


        
    function getRegisteredUsers() 
                                external 
                                view 
                                requirePlatformManager 
                                returns(address[]) 
    {
        return registeredUserLookup;
    }


        
    function getRegisteredUser
                                (
                                    address account
                                ) 
                                external 
                                view 
                                requirePlatformManager                                
                                returns(uint256, uint256, uint256, address) 
    {
        require(users[account].isRegistered);

        return (balances[account], users[account].seedJiffys, users[account].interfaceEscrowJiffys, users[account].referrer);
    }


      
    function getIcoInfo()
                                  public
                                  view
                                  returns(bool, uint256, uint256, uint256, uint256, uint256)
    {
        return (
                    balances[icoOwner] > 0, 
                    weiExchangeRate, 
                    centsExchangeRate, 
                    bonus20EndTimestamp, 
                    bonus10EndTimestamp, 
                    bonus5EndTimestamp
                );
    }

     
     
     

     
    function() 
                            external 
                            payable 
    {
        buy(msg.sender);
    }


     
    function buy
                            (
                                address account
                            ) 
                            public 
                            payable 
                            requireIsOperational 
    {
        require(balances[icoOwner] > 0);
        require(account != address(0));        
        require(msg.value >= weiExchangeRate);     

        uint256 weiReceived = msg.value;

         
        uint256 buyJiffys = weiReceived.mul(jiffysMultiplier).div(weiExchangeRate);
        processPurchase(icoOwner, account, buyJiffys, now);
        icoWallet.transfer(msg.value);
    }


         
    function buyUSD
                            (
                                address account,
                                uint256 cents
                            ) 
                            public 
                            requireIsOperational 
                            requirePlatformManager
    {
        require(balances[icoOwner] > 0);
        require(account != address(0));        
        require(cents >= centsExchangeRate);     



         
        uint256 buyJiffys = cents.mul(jiffysMultiplier).div(centsExchangeRate);

        if (users[account].isRegistered) {
            processPurchase(icoOwner, account, buyJiffys, now);
        } else {
             
             
             
             
             
            uint256 totalJiffys = buyJiffys.add(calculatePurchaseBonus(buyJiffys, now));
            balances[icoOwner] = balances[icoOwner].sub(totalJiffys);
            balances[account] = balances[account].add(totalJiffys);
            purchaseCredits[account] = PurchaseCredit(buyJiffys, now);
            Transfer(icoOwner, account, buyJiffys);
        }

    }

         
    function processPurchase
                            (
                                address source,
                                address account,
                                uint256 buyJiffys,
                                uint256 purchaseTimestamp
                            ) 
                            private 
    {

        uint256 totalJiffys = buyJiffys.add(calculatePurchaseBonus(buyJiffys, purchaseTimestamp));


         
        require(transferableBalanceOf(source) >= totalJiffys);        
        balances[source] = balances[source].sub(totalJiffys);
        balances[account] = balances[account].add(totalJiffys);            
        Transfer(source, account, totalJiffys);

         
         
        if (users[account].isRegistered && (users[account].referrer != address(0))) {
            address referrer = users[account].referrer;
            uint256 referralJiffys = (buyJiffys.mul(BUYER_REFERRER_BOUNTY)).div(100);
            if ((referralJiffys > 0) && (transferableBalanceOf(icoOwner) >= referralJiffys)) {
                balances[icoOwner] = balances[icoOwner].sub(referralJiffys);
                balances[referrer] = balances[referrer].add(referralJiffys);  
                Transfer(icoOwner, referrer, referralJiffys);
            }            
        }
    }

         
    function calculatePurchaseBonus
                            (
                                uint256 buyJiffys,
                                uint256 purchaseTimestamp
                            ) 
                            private 
                            view
                            returns(uint256)
    {
        uint256 bonusPercentage = 0;

         
        if (purchaseTimestamp <= bonus5EndTimestamp) {
            if (purchaseTimestamp <= bonus10EndTimestamp) {
                if (purchaseTimestamp <= bonus20EndTimestamp) {
                    bonusPercentage = 20;
                } else {
                    bonusPercentage = 10;
                }
            } else {
                bonusPercentage = 5;
            }
        }

        return (buyJiffys.mul(bonusPercentage)).div(100);
    }
    

}   

 


library SafeMath {
 
 

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
        return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
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