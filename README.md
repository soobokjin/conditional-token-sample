# Hardhat & Foundary Contract Skeletion

## Requirements

- config
  - hardhat, foundry 모두 동일한 설정을 공유해야 한다.
    - 설정을 변경하기 위해 동일한 config 를 사용하도록 해야한다.
- deployment
  - test 할 때와 동일한 solc version, library 를 이용하여 compile 되어야 한다
  - 배포는 hardhat 을 통해 진행하며, network 에 대해서는 단순히 설정 추가로 배포할 수 있어야 한다.
- test
  - unittest 는 foundry, integration test 는 hardhat 으로 할 수 있다.
  - 어떤 framework 를 사용하든 동일한 compile source 를 대상으로 테스트가 진행되어야 한다
  - forked 환경에서 테스트가 가능해야 한다.

## Management

- forge 와 hardhat 이 동일한 library 를 바라보고 build & test 할 수 있도록 하기 위해 forge 를 이용하여 install 한다.
- contract 에서 사용하는 외부 라이브러리는 `/lib` folder 에 모두 기록한다.
- `remapping.txt` 을 활용하여 import 구문을 간소화한다.
