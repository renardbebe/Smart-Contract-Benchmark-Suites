 

pragma solidity 0.4.24;

 
 
 
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

 
 
 
 
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

 
 
 
contract Owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

contract CasperToken is ERC20Interface, Owned {
    using SafeMath for uint;

    string public constant name = "Csper Token";
    string public constant symbol = "CST";
    uint8 public constant decimals = 18;

    uint constant public cstToMicro = uint(10) ** decimals;

     
    uint constant public _totalSupply    = 440000000 * cstToMicro;
    uint constant public preICOSupply    = 13000000 * cstToMicro;
    uint constant public presaleSupply   = 183574716 * cstToMicro;
    uint constant public crowdsaleSupply = 19750000 * cstToMicro;
    uint constant public communitySupply = 66000000 * cstToMicro;
    uint constant public systemSupply    = 35210341 * cstToMicro;
    uint constant public investorSupply  = 36714943 * cstToMicro;
    uint constant public teamSupply      = 66000000 * cstToMicro;
    uint constant public adviserSupply   = 7000000 * cstToMicro;
    uint constant public bountySupply    = 8800000 * cstToMicro;
    uint constant public referralSupply  = 3950000 * cstToMicro;

     
     
    uint public presaleSold = 0;
    uint public crowdsaleSold = 0;
    uint public investorGiven = 0;

     
    uint public ethSold = 0;

    uint constant public softcapUSD = 4500000;
    uint constant public preicoUSD  = 1040000;

     
    uint constant public crowdsaleMinUSD = cstToMicro * 10 * 100 / 12;
    uint constant public bonusLevel0 = cstToMicro * 10000 * 100 / 12;  
    uint constant public bonusLevel100 = cstToMicro * 100000 * 100 / 12;  

     
     
    uint constant public unlockDate1 = 1538179199;  
    uint constant public unlockDate2 = 1543622399;  
    uint constant public unlockDate3 = 1548979199;  
    uint constant public unlockDate4 = 1553903999;  
    uint constant public unlockDate5 = 1559347199;  

    uint constant public teamUnlock1 = 1549065600;  
    uint constant public teamUnlock2 = 1564704000;  
    uint constant public teamUnlock3 = 1580601600;  
    uint constant public teamUnlock4 = 1596326400;  

    uint constant public teamETHUnlock1 = 1535846400;  
    uint constant public teamETHUnlock2 = 1538438400;  
    uint constant public teamETHUnlock3 = 1541116800;  

     
     
     
    uint constant public presaleStartTime     = 1528588800;
    uint constant public crowdsaleStartTime   = 1532304000;
    uint          public crowdsaleEndTime     = 1533168000;
    uint constant public crowdsaleHardEndTime = 1534377600;
     
    constructor() public {
        admin = owner;
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }

    modifier onlyAdmin {
        require(msg.sender == admin);
        _;
    }

    modifier onlyOwnerAndDirector {
        require(msg.sender == owner || msg.sender == director);
        _;
    }

    address admin;
    function setAdmin(address _newAdmin) public onlyOwnerAndDirector {
        admin = _newAdmin;
    }

    address director;
    function setDirector(address _newDirector) public onlyOwner {
        director = _newDirector;
    }

    bool assignedPreico = false;
     
    function assignPreicoTokens() public onlyOwnerAndDirector {
        require(!assignedPreico);
        assignedPreico = true;

        _freezeTransfer(0xb424958766e736827Be5A441bA2A54bEeF54fC7C, 10 * 19514560000000000000000);
        _freezeTransfer(0xF5dF9C2aAe5118b64Cda30eBb8d85EbE65A03990, 10 * 36084880000000000000000);
        _freezeTransfer(0x5D8aCe48970dce4bcD7f985eDb24f5459Ef184Ec, 10 * 2492880000000000000000);
        _freezeTransfer(0xcD6d5b09a34562a1ED7857B19b32bED77417655b, 10 * 1660880000000000000000);
        _freezeTransfer(0x50f73AC8435E4e500e37FAb8802bcB840bf4b8B8, 10 * 94896880000000000000000);
        _freezeTransfer(0x65Aa068590216cb088f4da28190d8815C31aB330, 10 * 16075280000000000000000);
        _freezeTransfer(0x2046838D148196a5117C4026E21C165785bD3982, 10 * 5893680000000000000000);
        _freezeTransfer(0x458e1f1050C34f5D125437fcEA0Df0aA9212EDa2, 10 * 32772040882120167215360);
        _freezeTransfer(0x12B687E19Cef53b2A709e9b98C4d1973850cA53F, 10 * 70956080000000000000000);
        _freezeTransfer(0x1Cf5daAB09155aaC1716Aa92937eC1c6D45720c7, 10 * 3948880000000000000000);
        _freezeTransfer(0x32fAAdFdC7938E7FbC7386CcF546c5fc382ed094, 10 * 88188880000000000000000);
        _freezeTransfer(0xC4eA6C0e9d95d957e75D1EB1Fbe15694CD98336c, 10 * 81948880000000000000000);
        _freezeTransfer(0xB97D3d579d35a479c20D28988A459E3F35692B05, 10 * 121680000000000000000);
        _freezeTransfer(0x65AD745047633C3402d4BC5382f72EA3A9eCFe47, 10 * 5196880000000000000000);
        _freezeTransfer(0xd0BEF2Fb95193f429f0075e442938F5d829a33c8, 10 * 223388880000000000000000);
        _freezeTransfer(0x9Fc87C3d44A6374D48b2786C46204F673b0Ae236, 10 * 28284880000000000000000);
        _freezeTransfer(0x42C73b8945a82041B06428359a94403a2e882406, 10 * 13080080000000000000000);
        _freezeTransfer(0xa4c9595b90BBa7B4d805e555E477200C61711F3a, 10 * 6590480000000000000000);
        _freezeTransfer(0xb93b8ceD7CD86a667E12104831b4d514365F9DF8, 10 * 116358235759665569280);
        _freezeTransfer(0xa94F999b3f76EB7b2Ba7B17fC37E912Fa2538a87, 10 * 10389600000000000000000);
        _freezeTransfer(0xD65B9b98ca08024C3c19868d42C88A3E47D67120, 10 * 25892880000000000000000);
        _freezeTransfer(0x3a978a9Cc36f1FE5Aab6D31E41c08d8380ad0ACB, 10 * 548080000000000000000);
        _freezeTransfer(0xBD46d909D55d760E2f79C5838c5C42E45c0a853A, 10 * 7526480000000000000000);
        _freezeTransfer(0xdD9d289d4699fDa518cf91EaFA029710e3Cbb7AA, 10 * 3324880000000000000000);
        _freezeTransfer(0x8671B362902C3839ae9b4bc099fd24CdeFA026F4, 10 * 21836880000000000000000);
        _freezeTransfer(0xf3C25Ee648031B28ADEBDD30c91056c2c5cd9C6b, 10 * 132284880000000000000000);
        _freezeTransfer(0x1A2392fB72255eAe19BB626678125A506a93E363, 10 * 61772880000000000000000);
        _freezeTransfer(0xCE2cEa425f7635557CFC00E18bc338DdE5B16C9A, 10 * 105360320000000000000000);
        _freezeTransfer(0x952AD1a2891506AC442D95DA4C0F1AE70A27b677, 10 * 100252880000000000000000);
        _freezeTransfer(0x5eE1fC4D251143Da96db2a5cD61507f2203bf7b7, 10 * 80492880000000000000000);
    }

    bool assignedTeam = false;
     
     
    function assignTeamTokens() public onlyOwnerAndDirector {
        require(!assignedTeam);
        assignedTeam = true;

        _teamTransfer(0x1E21f744d91994D19f2a61041CD7cCA571185dfc, 13674375 * cstToMicro);  
        _teamTransfer(0x4CE4Ea57c40bBa26B7b799d5e0b4cd063B034c8A,  9920625 * cstToMicro);  
        _teamTransfer(0xdCd8a8e561d23Ca710f23E7612F1D4E0dE9bde83,  1340625 * cstToMicro);  
        _teamTransfer(0x0dFFA8624A1f512b8dcDE807F8B0Eab68672e5D5, 13406250 * cstToMicro);  
        _teamTransfer(0xE091180bB0C284AA0Bd15C6888A41aba45c54AF0, 13138125 * cstToMicro);  
        _teamTransfer(0xcdB7A51bA9af93a7BFfe08a31E4C6c5f9068A051,  3960000 * cstToMicro);  
        _teamTransfer(0x57Bd10E12f789B74071d62550DaeB3765Ad83834,  3960000 * cstToMicro);  
        _teamTransfer(0xEE74922eaF503463a8b20aFaD83d42F28D59f45d,  3960000 * cstToMicro);  
        _teamTransfer(0x58681a49A6f9D61eB368241a336628781afD5f87,  1320000 * cstToMicro);  

        _teamTransfer(0x3C4662b4677dC81f16Bf3c823A7E6CE1fF7e94d7,  80000 * cstToMicro);  
        _teamTransfer(0x041A1e96E0C9d3957613071c104E44a9c9d43996, 150000 * cstToMicro);  
        _teamTransfer(0xD63d63D2ADAF87B0Edc38218b0a2D27FD909d8B1, 100000 * cstToMicro);  
        _teamTransfer(0xd0d49Da78BbCBb416152dC41cc7acAb559Fb8275,  80000 * cstToMicro);  
        _teamTransfer(0x75FdfAc64c27f5B5f0823863Fe0f2ddc660A376F, 100000 * cstToMicro);  
        _teamTransfer(0xb66AFf323d97EF52192F170fF0F16D0a05Ebe56C,  60000 * cstToMicro);  
        _teamTransfer(0xec6234E34477f7A19cD3D67401003675522a4Fad,  60000 * cstToMicro);  
        _teamTransfer(0x1be50e8337F99983ECd4A4b15a74a5a795B73dF9,  40000 * cstToMicro);  
        _teamTransfer(0x4c14DB011065e72C6E839bd826d101Ec09d3C530, 833000 * cstToMicro);  
        _teamTransfer(0x7891C07b20fFf1918fAD43CF6fc7E3f83900f06d,  50000 * cstToMicro);  
        _teamTransfer(0x27996b3c1EcF2e7cbc5f31dE7Bca17EFCb398617, 150000 * cstToMicro);  
    }

     
     
    mapping(address => bool) public kyc;
    mapping(address => address) public referral;
    function kycPassed(address _mem, address _ref) public onlyAdmin {
        kyc[_mem] = true;
        if (_ref == richardAddr || _ref == wuguAddr) {
            referral[_mem] = _ref;
        }
    }

     
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

     
    mapping(address => uint) freezed;
    mapping(address => uint) teamFreezed;

     
    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function _transfer(address _from, address _to, uint _tokens) private {
        balances[_from] = balances[_from].sub(_tokens);
        balances[_to] = balances[_to].add(_tokens);
        emit Transfer(_from, _to, _tokens);
    }
    
    function transfer(address _to, uint _tokens) public returns (bool success) {
        checkTransfer(msg.sender, _tokens);
        _transfer(msg.sender, _to, _tokens);
        return true;
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        checkTransfer(from, tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        _transfer(from, to, tokens);
        return true;
    }

     
     
     
     
     
     
     
     
    function checkTransfer(address from, uint tokens) public view {
        uint newBalance = balances[from].sub(tokens);
        uint total = 0;
        if (now < unlockDate5) {
            require(now >= unlockDate1);
            uint frzdPercent = 0;
            if (now < unlockDate2) {
                frzdPercent = 80;
            } else if (now < unlockDate3) {
                frzdPercent = 60;
            } else if (now < unlockDate4) {
                frzdPercent = 40;
            } else {
                frzdPercent = 20;
            }
            total = freezed[from].mul(frzdPercent).div(100);
            require(newBalance >= total);
        }
        
        if (now < teamUnlock4 && teamFreezed[from] > 0) {
            uint p = 0;
            if (now < teamUnlock1) {
                p = 100;
            } else if (now < teamUnlock2) {
                p = 75;
            } else if (now < teamUnlock3) {
                p = 50;
            } else if (now < teamUnlock4) {
                p = 25;
            }
            total = total.add(teamFreezed[from].mul(p).div(100));
            require(newBalance >= total);
        }
    }

     
    function ICOStatus() public view returns (uint usd, uint eth, uint cst) {
        usd = presaleSold.mul(12).div(10**20) + crowdsaleSold.mul(16).div(10**20);
        usd = usd.add(preicoUSD);  

        return (usd, ethSold + preicoUSD.mul(10**8).div(ethRate), presaleSold + crowdsaleSold);
    }

    function checkICOStatus() public view returns(bool) {
        uint eth;
        uint cst;

        (, eth, cst) = ICOStatus();

        uint dollarsRecvd = eth.mul(ethRate).div(10**8);

         
        return dollarsRecvd >= 25228966 || (cst == presaleSupply + crowdsaleSupply) || now > crowdsaleEndTime;
    }

    bool icoClosed = false;
    function closeICO() public onlyOwner {
        require(!icoClosed);
        icoClosed = checkICOStatus();
    }

     
     
     
     
    uint bonusTransferred = 0;
    uint constant maxUSD = 4800000;
    function transferBonus(address _to, uint _usd) public onlyOwner {
        bonusTransferred = bonusTransferred.add(_usd);
        require(bonusTransferred <= maxUSD);

        uint cst = _usd.mul(100).mul(cstToMicro).div(12);  
        presaleSold = presaleSold.add(cst);
        require(presaleSold <= presaleSupply);
        ethSold = ethSold.add(_usd.mul(10**8).div(ethRate));

        _freezeTransfer(_to, cst);
    }

     
    function prolongCrowdsale() public onlyOwnerAndDirector {
        require(now < crowdsaleEndTime);
        crowdsaleEndTime = crowdsaleHardEndTime;
    }

     
    uint public ethRate = 0;
    uint public ethRateMax = 0;
    uint public ethLastUpdate = 0;
    function setETHRate(uint _rate) public onlyAdmin {
        require(ethRateMax == 0 || _rate < ethRateMax);
        ethRate = _rate;
        ethLastUpdate = now;
    }

     
    uint public btcRate = 0;
    uint public btcRateMax = 0;
    uint public btcLastUpdate;
    function setBTCRate(uint _rate) public onlyAdmin {
        require(btcRateMax == 0 || _rate < btcRateMax);
        btcRate = _rate;
        btcLastUpdate = now;
    }

     
     
    function setMaxRate(uint ethMax, uint btcMax) public onlyOwnerAndDirector {
        ethRateMax = ethMax;
        btcRateMax = btcMax;
    }

     
    function _sellPresale(uint cst) private {
        require(cst >= bonusLevel0.mul(9950).div(10000));
        presaleSold = presaleSold.add(cst);
        require(presaleSold <= presaleSupply);
    }

     
    function _sellCrowd(uint cst, address _to) private {
        require(cst >= crowdsaleMinUSD);

        if (crowdsaleSold.add(cst) <= crowdsaleSupply) {
            crowdsaleSold = crowdsaleSold.add(cst);
        } else {
            presaleSold = presaleSold.add(crowdsaleSold).add(cst).sub(crowdsaleSupply);
            require(presaleSold <= presaleSupply);
            crowdsaleSold = crowdsaleSupply;
        }

        if (now < crowdsaleStartTime + 3 days) {
            if (whitemap[_to] >= cst) {
                whitemap[_to] -= cst;
                whitelistTokens -= cst;
            } else {
                require(crowdsaleSupply.add(presaleSupply).sub(presaleSold) >= crowdsaleSold.add(whitelistTokens));
            }
        }
    }

     
    function addInvestorBonusInPercent(address _to, uint8 p) public onlyOwner {
        require(p > 0 && p <= 5);
        uint bonus = balances[_to].mul(p).div(100);

        investorGiven = investorGiven.add(bonus);
        require(investorGiven <= investorSupply);

        _freezeTransfer(_to, bonus);
    }
 
     
    function addInvestorBonusInTokens(address _to, uint tokens) public onlyOwner {
        _freezeTransfer(_to, tokens);
        
        investorGiven = investorGiven.add(tokens);
        require(investorGiven <= investorSupply);
    }

    function () payable public {
        purchaseWithETH(msg.sender);
    }

     
     
    function _freezeTransfer(address _to, uint cst) private {
        _transfer(owner, _to, cst);
        freezed[_to] = freezed[_to].add(cst);
    }

     
     
    function _teamTransfer(address _to, uint cst) private {
        _transfer(owner, _to, cst);
        teamFreezed[_to] = teamFreezed[_to].add(cst);
    }

    address public constant wuguAddr = 0x096ad02a48338CB9eA967a96062842891D195Af5;
    address public constant richardAddr = 0x411fB4D77EDc659e9838C21be72f55CC304C0cB8;
    mapping(address => address[]) promoterClients;
    mapping(address => mapping(address => uint)) promoterBonus;

     
     
    function withdrawPromoter() public {
        address _to = msg.sender;
        require(_to == wuguAddr || _to == richardAddr);

        uint usd;
        (usd,,) = ICOStatus();

         
        require(usd.mul(95).div(100) >= softcapUSD);

        uint bonus = 0;
        address[] memory clients = promoterClients[_to];
        for(uint i = 0; i < clients.length; i++) {
            if (kyc[clients[i]]) {
                uint num = promoterBonus[_to][clients[i]];
                delete promoterBonus[_to][clients[i]];
                bonus += num;
            }
        }
        
        _to.transfer(bonus);
    }

     
     
    function cashBack(address _to) public {
        uint usd;
        (usd,,) = ICOStatus();

         
        require(now > crowdsaleEndTime && usd < softcapUSD);
        require(ethSent[_to] > 0);

        delete ethSent[_to];

        _to.transfer(ethSent[_to]);
    }

     
    mapping(address => uint) ethSent;

    function purchaseWithETH(address _to) payable public {
        purchaseWithPromoter(_to, referral[msg.sender]);
    }

     
     
    function purchaseWithPromoter(address _to, address _ref) payable public {
        require(now >= presaleStartTime && now <= crowdsaleEndTime);

        require(!icoClosed);
    
        uint _wei = msg.value;
        uint cst;

        ethSent[msg.sender] = ethSent[msg.sender].add(_wei);
        ethSold = ethSold.add(_wei);

         
         
        if (now < crowdsaleStartTime || approvedInvestors[msg.sender]) {
            require(kyc[msg.sender]);
            cst = _wei.mul(ethRate).div(12000000);  

            require(now < crowdsaleStartTime || cst >= bonusLevel100);

            _sellPresale(cst);

             
            if (_ref == wuguAddr || _ref == richardAddr) {
                promoterClients[_ref].push(_to);
                promoterBonus[_ref][_to] = _wei.mul(5).div(100);
            }
        } else {
            cst = _wei.mul(ethRate).div(16000000);  
            _sellCrowd(cst, _to);
        }

        _freezeTransfer(_to, cst);
    }

     
     
    function purchaseWithBTC(address _to, uint _satoshi, uint _wei) public onlyAdmin {
        require(now >= presaleStartTime && now <= crowdsaleEndTime);

        require(!icoClosed);

        ethSold = ethSold.add(_wei);

        uint cst;
         
         
        if (now < crowdsaleStartTime || approvedInvestors[msg.sender]) {
            require(kyc[msg.sender]);
            cst = _satoshi.mul(btcRate.mul(10000)).div(12);  

            require(now < crowdsaleStartTime || cst >= bonusLevel100);

            _sellPresale(cst);
        } else {
            cst = _satoshi.mul(btcRate.mul(10000)).div(16);  
            _sellCrowd(cst, _to);
        }

        _freezeTransfer(_to, cst);
    }

     
     
    bool withdrawCalled = false;
    function withdrawFunds() public onlyOwner {
        require(icoClosed && now >= teamETHUnlock1);

        require(!withdrawCalled);
        withdrawCalled = true;

        uint eth;
        (,eth,) = ICOStatus();

         
        uint minus = bonusTransferred.mul(10**8).div(ethRate);
        uint team = ethSold.sub(minus);

        team = team.mul(15).div(100);

        uint ownerETH = 0;
        uint teamETH = 0;
        if (address(this).balance >= team) {
            teamETH = team;
            ownerETH = address(this).balance.sub(teamETH);
        } else {
            teamETH = address(this).balance;
        }

        teamETH1 = teamETH.div(3);
        teamETH2 = teamETH.div(3);
        teamETH3 = teamETH.sub(teamETH1).sub(teamETH2);

         
        address(0x741A26104530998F625D15cbb9D58b01811d2CA7).transfer(ownerETH);
    }

    uint teamETH1 = 0;
    uint teamETH2 = 0;
    uint teamETH3 = 0;
    function withdrawTeam() public {
        require(now >= teamETHUnlock1);

        uint amount = 0;
        if (now < teamETHUnlock2) {
            amount = teamETH1;
            teamETH1 = 0;
        } else if (now < teamETHUnlock3) {
            amount = teamETH1 + teamETH2;
            teamETH1 = 0;
            teamETH2 = 0;
        } else {
            amount = teamETH1 + teamETH2 + teamETH3;
            teamETH1 = 0;
            teamETH2 = 0;
            teamETH3 = 0;
        }

        address(0xcdB7A51bA9af93a7BFfe08a31E4C6c5f9068A051).transfer(amount.mul(6).div(100));  
        address(0x57Bd10E12f789B74071d62550DaeB3765Ad83834).transfer(amount.mul(6).div(100));  
        address(0xEE74922eaF503463a8b20aFaD83d42F28D59f45d).transfer(amount.mul(6).div(100));  
        address(0x58681a49A6f9D61eB368241a336628781afD5f87).transfer(amount.mul(2).div(100));  
        address(0x4c14DB011065e72C6E839bd826d101Ec09d3C530).transfer(amount.mul(2).div(100));  

        amount = amount.mul(78).div(100);

        address(0x1E21f744d91994D19f2a61041CD7cCA571185dfc).transfer(amount.mul(uint(255).mul(100).div(96)).div(1000));  
        address(0x4CE4Ea57c40bBa26B7b799d5e0b4cd063B034c8A).transfer(amount.mul(uint(185).mul(100).div(96)).div(1000));  
        address(0xdCd8a8e561d23Ca710f23E7612F1D4E0dE9bde83).transfer(amount.mul(uint(25).mul(100).div(96)).div(1000));   
        address(0x0dFFA8624A1f512b8dcDE807F8B0Eab68672e5D5).transfer(amount.mul(uint(250).mul(100).div(96)).div(1000));  
        address(0xE091180bB0C284AA0Bd15C6888A41aba45c54AF0).transfer(amount.mul(uint(245).mul(100).div(96)).div(1000));  
    }

     
     
    uint dropped = 0;
    function doAirdrop(address[] members, uint[] tokens) public onlyOwnerAndDirector {
        require(members.length == tokens.length);
    
        for(uint i = 0; i < members.length; i++) {
            _freezeTransfer(members[i], tokens[i]);
            dropped = dropped.add(tokens[i]);
        }
        require(dropped <= bountySupply);
    }

    mapping(address => uint) public whitemap;
    uint public whitelistTokens = 0;
     
     
     
    function addWhitelistMember(address[] _mem, uint[] _tokens) public onlyAdmin {
        require(_mem.length == _tokens.length);
        for(uint i = 0; i < _mem.length; i++) {
            whitelistTokens = whitelistTokens.sub(whitemap[_mem[i]]).add(_tokens[i]);
            whitemap[_mem[i]] = _tokens[i];
        }
    }

    uint public adviserSold = 0;
     
     
    function transferAdviser(address[] _adv, uint[] _tokens) public onlyOwnerAndDirector {
        require(_adv.length == _tokens.length);
        for (uint i = 0; i < _adv.length; i++) {
            adviserSold = adviserSold.add(_tokens[i]);
            _freezeTransfer(_adv[i], _tokens[i]);
        }
        require(adviserSold <= adviserSupply);
    }

    mapping(address => bool) approvedInvestors;
    function approveInvestor(address _addr) public onlyOwner {
        approvedInvestors[_addr] = true;
    }
}