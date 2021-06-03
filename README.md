# ERC20-Exchanger-Governer
#### Governing Contract ( Which is inherited from Govern ERC20 Contract)
    - I inspired the Governing idea from Uniswap.
    - Used several mappings with structs to keep track of proposals and votes.
    - I used a mapping of (address => boolean) in order to keep track of registered tokens.
    - Only delegated users can vote with the number of votes which is determined before the proposal.
#### Exchange Contract
    - I used the Exchange Contract given with homework documents but with some modifications.
        - Saved the Governer address to the storage.
        - When a user wants to exchange a token, I checked the Governer’s registered tokens mapping to accept the exchange request or reject.

###Governing Pipeline:
To start the pipeline, firstly Governing Contract is deployed. In the constructor of the Governing Contract, a total of 1000 Gov token is given to the deployer. The deployer will distribute the Gov tokens to the community. If a user wants to propose a token to register in the exchange contract, the token shouldn’t be registered before or actively voting. Also, the user should have at least the threshold of 4% of the total supply which is 40. If all the conditions are met, the user can propose a token. After the user proposes a token, a voting period starts. Anyone can vote as yes or no if he/she delegates someone(including her/himself) before the proposal time. Anyone can cancel the proposal if the proposer does not have more tokens than the threshold. After the voting period ends, if there are at least 100 votes in yes and votes of yes are more than votes of no, then this proposal succeeds. If the proposal succeeds, anyone can cancel the proposal or register the proposed token.
###Further Improvements
In the Govern Contract, I keep a mapping of (address => proposal) which keeps all the proposal results and states but I do not keep the track of the history of every proposal, I only keep the last proposal for each token address. I could improve this and give each proposal a unique id and could keep the history of each proposal. With the current implementation, there must be someone who financially supports the exchange token in order to exchange the tokens. A liquidity system that Uniswap implemented can be managed in order to source the exchange contract and make the community gain money. Also, there is only a 1-to-1 option for the exchange of the tokens, as Uniswap implements, there can be math operations that keep the balance of the values of the tokens and exchange rates. Other than these improvements, I think my implementation is good enough to establish a full-fledged governance pipeline.
