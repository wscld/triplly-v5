import { createConfig } from '@gluestack-ui/themed';
import { config as defaultConfig } from '@gluestack-ui/config';

export const config = createConfig({
    ...defaultConfig,
    tokens: {
        ...defaultConfig.tokens,
        colors: {
            ...defaultConfig.tokens.colors,
            primary0: '#E6F4FE',
            primary50: '#E6F4FE',
            primary100: '#CCE9FD',
            primary200: '#99D3FB',
            primary300: '#66BDF9',
            primary400: '#33A7F7',
            primary500: '#0091F5',
            primary600: '#0074C4',
            primary700: '#005793',
            primary800: '#003A62',
            primary900: '#001D31',
        },
    },
});
