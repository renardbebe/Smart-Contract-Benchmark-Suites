 

pragma solidity ^ 0.4 .6;

contract Campaign {

        address public JohanNygren;
        bool public campaignOpen;

        function Campaign() {
                JohanNygren = 0x948176cb42b65d835ee4324914b104b66fb93b52;
                campaignOpen = true;
        }

        modifier onlyJohan {
                if (msg.sender != JohanNygren) throw;
                _;
        }

        modifier isOpen {
                if (campaignOpen != true) throw;
                _;
        }

        function closeCampaign() onlyJohan {
                campaignOpen = false;
        }

}



contract RES is Campaign {

         
        string public name;
        string public symbol;
        uint8 public decimals;

        uint public totalSupply;

         
        mapping(address => uint256) public balanceOf;

         
        event Transfer(address indexed from, address indexed to, uint256 value);

         

        event Bought(address from, uint amount);
        event Sold(address from, uint amount);

         

        function RES() {
                name = "RES";
                symbol = "RES";
                decimals = 18;
        }

        function buy() isOpen public payable {
                balanceOf[msg.sender] += msg.value;
                totalSupply += msg.value;
                Bought(msg.sender, msg.value);
        }

        function sell(uint256 _value) public {
                if (balanceOf[msg.sender] < _value) throw;
                balanceOf[msg.sender] -= _value;

                if (!msg.sender.send(_value)) throw;

                totalSupply -= _value;
                Sold(msg.sender, _value);

        }

}

contract SwarmRedistribution is Campaign, RES {

        struct dividendPathway {
                address from;
                uint amount;
                uint timeStamp;
        }

        mapping(address => dividendPathway[]) public dividendPathways;

        mapping(address => bool) public isHuman;

        mapping(address => uint256) public totalBasicIncome;

        uint taxRate;
        uint exchangeRate;

        address[] humans;
        mapping(address => bool) inHumans;

        event Swarm(address indexed leaf, address indexed node, uint256 share);

        function SwarmRedistribution() {

                 
                taxRate = 20;

                 
                exchangeRate = 0;

        }

         
        function transfer(address _to, uint256 _value) isOpen {
                 
                if (_to == msg.sender) throw;

                 
                if (balanceOf[msg.sender] < _value) throw;
                if (balanceOf[_to] + _value < balanceOf[_to]) throw;

                 
                uint256 taxCollected = _value * taxRate / 1000;
                uint256 sentAmount;

                 
                dividendPathways[_to].push(dividendPathway({
                        from: msg.sender,
                        amount: _value,
                        timeStamp: now
                }));

                iterateThroughSwarm(_to, now, taxCollected);

                if (humans.length > 0) {
                        doSwarm(_to, taxCollected);
                        sentAmount = _value;
                } else sentAmount = _value - taxCollected;  


                 

                balanceOf[msg.sender] -= sentAmount;
                balanceOf[_to] += _value - taxCollected;

                 
                Transfer(msg.sender, _to, sentAmount);
        }


        function iterateThroughSwarm(address _node, uint _timeStamp, uint _taxCollected) internal {
                for (uint i = 0; i < dividendPathways[_node].length; i++) {

                        uint timeStamp = dividendPathways[_node][i].timeStamp;
                        if (timeStamp <= _timeStamp) {

                                address node = dividendPathways[_node][i].from;

                                if (
                                        isHuman[node] == true &&
                                        inHumans[node] == false
                                ) {
                                        humans.push(node);
                                        inHumans[node] = true;
                                }

                                if (dividendPathways[_node][i].amount - _taxCollected > 0) {
                                        dividendPathways[_node][i].amount -= _taxCollected;
                                } else removeDividendPathway(_node, i);

                                iterateThroughSwarm(node, timeStamp, _taxCollected);
                        }
                }
        }

        function doSwarm(address _leaf, uint256 _taxCollected) internal {

                uint256 share = _taxCollected / humans.length;

                for (uint i = 0; i < humans.length; i++) {

                        balanceOf[humans[i]] += share;
                        totalBasicIncome[humans[i]] += share;

                        inHumans[humans[i]] = false;

                         
                        Swarm(_leaf, humans[i], share);
                }
                delete humans;
        }

        function removeDividendPathway(address node, uint index) internal {
                delete dividendPathways[node][index];
                for (uint i = index; i < dividendPathways[node].length - 1; i++) {
                        dividendPathways[node][i] = dividendPathways[node][i + 1];
                }
                dividendPathways[node].length--;
        }

}

contract CampaignBeneficiary is Campaign, RES, SwarmRedistribution {

        event BuyWithPathwayFromBeneficiary(address from, uint amount);

        function CampaignBeneficiary() {
                isHuman[JohanNygren] = true;
        }

        function simulatePathwayFromBeneficiary() isOpen public payable {
                balanceOf[msg.sender] += msg.value;
                totalSupply += msg.value;

                 
                dividendPathways[msg.sender].push(dividendPathway({
                        from: JohanNygren,
                        amount: msg.value,
                        timeStamp: now
                }));

                BuyWithPathwayFromBeneficiary(msg.sender, msg.value);
        }

}